use Getopt::Long;
use Config::General;
use DBI;
use DBD::mysql;
use Digest::MD5 qw(md5_hex);
use Sys::Hostname;
use Proc::Daemon;
use Data::Dumper;

use constant DEBUG => 1;

my $hostname = hostname();

my $db_config_file = '../etc/db.conf';
my $daemonize = 0;
my $help = 0;

GetOptions("db_config_file|c=s" => \$db_config_file,
					 "daemonize|d" => \$daemonize,
					 "help|h" => \$help,
					);
					
usage_and_die() if $help;
						
my $conf = new Config::General($db_config_file) || die "Could not open config file: $db_config_file\n";
my %config = $conf->getall;

my $db_host = $config{'db_host'};
my $db_user = $config{'db_user'};
my $db_pass = $config{'db_pass'};
my $db_name = $config{'db_name'};
my $db_table = 'jobs';

my $run_user = 'system';
my $run_group = 'system';

my $time_to_die = 0;

unless (getpwuid($>) eq $run_user) { # Check to make sure we are running as root so we can drop privileges.
	die "Aborting. This program must be run as the user: $run_user.\n";	
}

# Check to see if we're already running, we only need one of these.
if (open(PID, '/home/system/worker-transcode-mp4/pid.txt')) {
	my $pid = <PID>;
	close PID;
	my $running = kill (0, $pid);
	if ($running) {
		die "Daemon is already running. Aborting...\n";
	}
}

# Unbuffered output, please
$|++;

if ($daemonize) {
	my $daemon = Proc::Daemon->new(
		work_dir => '/home/system/worker-transcode-mp4',
		child_STDOUT => '+>>log.txt',
		pid_file => 'pid.txt',
		);
		
		$daemon->Init;
}

$SIG{TERM} = $SIG{INT} = \&terminate;

while (!$time_to_die) {

	# Fetch SCP Configuration values from conf table
	my $scp_bw = 10000000;
	my $scp_cipher = 'blowfish';
	my $sleep_interval = 30;

	my $dbh = DBI->connect(
		"DBI:mysql:database=$db_name;host=$db_host",
		"$db_user",
		"$db_pass",
	  {'RaiseError' => 1}
	) || die "Could not connect to MySQL Server\n";


	my $sth = $dbh->prepare("SELECT * FROM $db_table WHERE job_type = 'transcode_mp4' AND job_status = 'ready' ORDER BY job_id ASC LIMIT 1");
	$sth->execute();

	unless ($sth->rows()) {
		print "No work to do. Sleeping for $sleep_interval seconds\n" if DEBUG;
		sleep $sleep_interval;
		next;
	}

	while (my $ref = $sth->fetchrow_hashref()) {
		my $job_id = $ref->{'job_id'};
		my $event_name = $ref->{'event_name'};
		my $card_name = $ref->{'card_name'};
		my $src_ip = $ref->{'src_ip'};
		my $src_path = $ref->{'src_path'};
		my $dst_path = $ref->{'dst_path'};
		
		print "Received transcode_mp4 job: $job_id || $event_name || $card_name || $src_ip || $src_path || $dst_path\n";

		my @dst_path_parts = split('/', $dst_path);
		
		print Dumper @dst_path_parts;

		shift @dst_path_parts;
		my $dst_file = pop @dst_path_parts;

		my $create_dir;
		foreach my $pathpart (@dst_path_parts) {
			$create_dir .= "/$pathpart";
			unless (-e "$create_dir") {
				system("mkdir $create_dir");
			}
		}

		my $start_time = time();
		
		$dbh->do("UPDATE jobs SET job_status = 'copying', proc_host = ? WHERE job_id = ?", undef, $hostname, $job_id) || die $dbh->errstr;
		
		my $scp_quiet = $daemonize ? '-q' : '';
		
		print "JobID: $job_id - Fetching via SCP: $src_path $dst_path.\n";
		my $scpret = system("/usr/bin/scp $scp_quiet -B -l $scp_bw -c $scp_cipher system\@$src_ip\:$src_path $dst_path");
		
		if ($scpret == -1) {
			print "JobID: $job_id - SCP job failed to START; reseting status to ready for another runner; backing off.\n";
			$dbh->do("UPDATE jobs SET job_status = 'ready' WHERE job_id = ?", undef, $job_id) || die $dbh->errstr;
			sleep $sleep_interval;
		} elsif ($scpret) {
			print "JobID: $job_id - SCP job failed; reseting status to ready for another runner; backing off.\n";
			$dbh->do("UPDATE jobs SET job_status = 'ready' WHERE job_id = ?", undef, $job_id) || die $dbh->errstr;
			sleep $sleep_interval;
		} else { 
			my $end_time = time();
			my $network_time = $end_time - $start_time;
			print "JobID: $job_id - SCP job finished successfully: $network_time seconds.\n";
			$dbh->do("UPDATE jobs SET network_time = ? WHERE job_id = ?", undef, $network_time, $job_id) || die $dbh->errstr;

			# Wait here if ffmpeg is running
			print "Checking for running ffmpeg job.\n";

			while  (qx/pgrep ffmpeg/) {
				print "FFmpeg process is running, blocking and sleeping for $sleep_interval seconds.\n";
				sleep $sleep_interval;
			}
			
			# Fork the ffmpeg process so we can keep copying.
			my $forkpid = fork();
			
			unless ($forkpid) {
				# This is the child

				$dbh = DBI->connect(
					"DBI:mysql:database=$db_name;host=$db_host",
					"$db_user",
					"$db_pass",
				  {'RaiseError' => 1}
				) || die "Could not connect to MySQL Server\n";

				$dbh->do("UPDATE jobs SET job_status = 'encoding', proc_host = ? WHERE job_id = ?", undef, $hostname, $job_id) || die $dbh->errstr;


				my $path_1080 = $create_dir;

				$create_dir =~ s/1080p/360p/;

				unless (-e "$create_dir") {
					system("mkdir $create_dir");
				}
				
				my $path_360 = $create_dir;
				
				print "JobID: $job_id - Starting up FFmpeg.\n";
				$start_time = time();
	
				my $ffmpeg_quiet = $daemonize ? '-loglevel quiet -benchmark' : '';
					
				my $ffmpegret = system("/usr/bin/ffmpeg $ffmpeg_quiet -i $path_1080\/$dst_file -vf scale=640:360 -crf 25.0 -vcodec libx264 -acodec libvo_aacenc -ar 48000 -b:a 128k -coder 1 -rc_lookahead 60 -threads 0 -y $path_360\/$dst_file");

				$dbh = DBI->connect(
					"DBI:mysql:database=$db_name;host=$db_host",
					"$db_user",
					"$db_pass",
				  {'RaiseError' => 1}
				) || die "Could not connect to MySQL Server\n";

				if ($ffmpegret == -1) {
					print "JobID: $job_id - FFmeg job failed to START; reseting status to ready for another runner; backing off.\n";
					$dbh->do("UPDATE jobs SET job_status = 'ready' WHERE job_id = ?", undef, $job_id) || die $dbh->errstr;
					sleep $sleep_interval;
				} elsif ($ffmpegret) {
					print "JobID: $job_id - FFmpeg job failed; reseting status to ready for another runner; backing off.\n";
					$dbh->do("UPDATE jobs SET job_status = 'ready' WHERE job_id = ?", undef, $job_id) || die $dbh->errstr;
					sleep $sleep_interval;
				} else { 
					$end_time = time();
					my $encode_time = $end_time - $start_time;
					print "JobID: $job_id - FFMPEG job finished successfully: $encode_time seconds.\n";
					$dbh->do("UPDATE jobs SET job_status = 'complete', encode_time = ? WHERE job_id = ?", undef, $encode_time, $job_id) || die $dbh->errstr;
				}

				exit 1;
				# The child process just dies.
			}

			# And the parent just loops around.
		} 
	}
}
	
print "Exiting...\n";
exit;

sub terminate {
	print "Received TERM, finishing job and exiting...\n";
	$time_to_die = 1;
}

sub usage_and_die {
	print "Usage:\n";
	print " -c | --db_config_file: Database config file. Defaults to ../etc/db.conf.\n";
	print " -d | --daemonize: Run as a daemon.\n";
	print " -h | --help: Print this help.\n";
	exit;
}
