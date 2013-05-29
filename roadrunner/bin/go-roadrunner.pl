#!/usr/bin/perl

# go-roadrunner will find all SDXC cards mounted on a box, find all MP4 or LRV files on the cards, and queue them into the database for processing by the encoding machines.

use strict;
use warnings;

use Getopt::Long;
use Config::General;
use File::Util;
use DBI;
use DBD::mysql;
use Digest::MD5 qw(md5_hex);
use Sys::Hostname;
use Data::Dumper;

use constant DEBUG => 0;

my $hostname = hostname();

my $db_config_file = '/usr/local/fleye/roadrunner/etc/db.conf';
my $local_card_path;
my $mount_cards = 0;
my $unmount_cards = 0;
my $truncate_jobs = 0;
my $force = 0;
my $status_report = 0;
my $help = 0;

GetOptions("db_config_file|c=s" => \$db_config_file,
					 "local_path_glob|l=s" => \$local_card_path,
					 "mount_cards|m" => \$mount_cards,
					 "unmount_cards|u" => \$unmount_cards,
					 "truncate_jobs|t" => \$truncate_jobs,
					 "force|f" => \$force,
					 "status_report|s" => \$status_report,
					 "help|h" => \$help,
					);

usage_and_die() if ($mount_cards && $local_card_path);
usage_and_die() if $help;
						
my $conf = new Config::General($db_config_file) || die "Could not open config file: $db_config_file\n";
my %config = $conf->getall;

my $db_host = $config{'db_host'};
my $db_user = $config{'db_user'};
my $db_pass = $config{'db_pass'};
my $db_name = $config{'db_name'};
my $db_table = 'jobs';

my $run_user = 'root';
my $run_group = 'root';

unless (getpwuid($>) eq $run_user) { # Check to make sure we are running as root so we can drop privileges.
	die "This program must be run as the user: $run_user. We need permission to perform mount/unmount commands.\n";	
}


my $event_name = 'default'; # We specify an event name for tracking.

my $dbh = DBI->connect(
	"DBI:mysql:database=$db_name;host=$db_host",
	"$db_user",
	"$db_pass",
  {'RaiseError' => 1}
) || die "Could not connect to MySQL Server\n";

if ($truncate_jobs) {
	my $sth = $dbh->prepare("SELECT * FROM $db_table WHERE job_status != 'complete'");
	$sth->execute();

	if ($sth->rows && !$force) {
		die "Jobs are running on cards. Aborting...\n";
	}

	print "Truncating jobs table\n";
	$dbh->do("TRUNCATE TABLE jobs") || die $dbh->errstr;
	die "Truncated jobs table\n";
}

if ($unmount_cards) {
	my $sth = $dbh->prepare("SELECT * FROM $db_table WHERE job_status != 'complete'");
	$sth->execute();

	if ($sth->rows && !$force) {
		die "Jobs are running on cards. Aborting...\n";
	}

	print "Unmounting cards.\n";

	my $mount_prefix = 'card';
	
	my @devices = ('b' .. 'am');
	
	foreach my $device (@devices) {
		my $mount_name = "/card-sd" . $device . '1';
		
		print "Unmounting $mount_name: ";
		my $umountret = system("/bin/umount $mount_name");
		
		if ($umountret == -1) {
			print "Call to /bin/umount failed. Aborting $mount_name.\n";
			next;
		} elsif ($umountret) {
			print "Failed to unmount filesystem from $mount_name. Skipping...\n";
			next;
		} else {
			print "OK...\n";
		}
	}
	
	print "\n\nMounted devices:\n";
	system("/bin/mount");

	die "\nUmounting complete. Check mount output above before removing cards.\n";
}

if ($status_report) {
	status_report();
	exit;
}

unless ($local_card_path || $mount_cards) {
	status_report();
	exit;
}

# Mainline program runs from here. Setup a global batch ID for this run.
my $rand = 100000 * rand();
my $rand_md5 = md5_hex($rand);
my $batch_id = substr(md5_hex($rand_md5), 0, 6);
print "go-roadrunner.pl global batch ID: $batch_id\n";

my @card_dirs;

if ($local_card_path) {
	@card_dirs = glob("$local_card_path*");

	if (DEBUG) {
			print "Processing local card path glob. Found directories:\n";
			print join("\n", @card_dirs);
			print "\n\n";
	}

}

if ($mount_cards) {
	my $mount_prefix = 'card';
	
	my @devices = ('b' .. 'am');
	
	foreach my $device (@devices) {
		$device = "sd" . $device;
		
		print "Checking for device: $device\n";
		if (-e "/dev/$device") {
			# print "Found device: $device - enumerating all slices by false mount.\n";
			# system("/bin/mount -f /dev/$device");
		
			my $devnode = $device . '1';
		
			if (-e "/dev/$devnode") {
				print "Found devnode: $devnode - checking for corresponding card directory.\n" if DEBUG;
		
				my $carddir = "/$mount_prefix-$devnode";
		
				unless (-e $carddir) {
					print "Cannot find card directory - creating...\n";
					system("mkdir $carddir");
				}
			
				print "Attempting exfat mount of $devnode to $carddir: \n";

				my $mountret = system("/usr/sbin/mount.exfat /dev/$devnode $carddir");

				if ($mountret == -1) {
					print "Call to /usr/sbin/mount.exfat failed. Aborting device $devnode.\n";
					next;
				} elsif ($mountret) {
					print "Failed to mount valid ExFAT filesystem from $devnode. Skipping...\n";
					next;
				} else {
					push (@card_dirs, $carddir);
					print "Mounted...\n";
				}
			}
		}
	}
	
	print "\n\nSummary of mounted devices:\n";
	system("/bin/mount");
	print "\n\n";

}

foreach my $dir (@card_dirs) {
	print "Searching for video files on: $dir\n";
	my ($event_name, $card_name) = extract_manifest($dir);

	my @video_files = find_files($dir);

	foreach my $file (@video_files) {
		print "Processing video file: $file\n" if DEBUG;
		create_job($event_name, $card_name, $file);
	}
}

print "End of Batch: $batch_id\n";

status_report();

# End main program. Enter subroutines.

sub extract_manifest {
		my $path = shift @_;
		
		my ($event_name, $card_name);
		
		if (open(MANIFEST, "$path/manifest.txt")) {
			my %items;
			while(<MANIFEST>) {
				chomp;
				my ($key, $value) = split(':');
				if ($key) {
					$items{$key} = $value;
				}
			}
			close MANIFEST;

			# generate a random suffix on the event and card name
			$event_name = join('-', $items{'event_name'}, $batch_id);
			$card_name = join('-', $items{'card_name'}, $batch_id);

		} else { # No manifest file was found.
			my ($card_path) = $path =~ m/^\/([\w-]+)\/?/;
			$event_name = join('-', 'event', $batch_id);
			$card_name = join('-', 'card', $card_path, $batch_id);
		}
		
		return ($event_name, $card_name);		
}

sub find_files {
	my $path = shift @_;

	my $f = File::Util->new();

	my @card_files = $f->list_dir("$path", '--recurse');
	
	my @video_files;
	
	foreach my $file (@card_files) {
		print "Found file: $file\n";
		if ($file =~ /\.LRV$/i) {
			push (@video_files, $file);
		} elsif ($file =~ /\.MP4$/i) {
			push (@video_files, $file);
		} else {
			next;
		}
	}

	return @video_files;
}

sub create_job {
	my ($event_name, $card_name, $file) = @_;

	$file =~ m/\/([\w-]+)\.(MP4|LRV)$/;
	my $basename = $1;
	my $extension = $2;
	print "Dissecting file - Filename: $file | Basename: $basename | Extension: $extension\n" if DEBUG;
	
	# Extract the size and timestamp from the file.
	my @file_stat = stat($file);
	my $file_bytes = $file_stat[7];
	my $file_ctime_epoch = $file_stat[10];

	my @ctime = localtime($file_ctime_epoch);
	
	my $ctime_year = $ctime[5]+1900;
	my $ctime_month = sprintf("%02d", $ctime[4]+1);
	my $ctime_day = sprintf("%02d", $ctime[3]);
	my $ctime_hour = sprintf("%02d", $ctime[2]);
	my $ctime_min = sprintf("%02d", $ctime[1]);
	my $ctime_sec = sprintf("%02d", $ctime[0]);

	my $renamed_file = $ctime_year . $ctime_month . $ctime_day . $ctime_hour . $ctime_min . $ctime_sec . '_' . $basename . '.mp4';

	my $job_type;
	my $dst_path;
	if ($extension eq 'MP4'){
		$job_type = 'transcode_mp4';
		$dst_path = "/MOSS/go-fleye/$event_name/$card_name/1080p/$renamed_file";
	} elsif ($extension eq 'LRV') {
		$job_type = 'copy_lrv';
		$dst_path = "/MOSS/go-fleye/$event_name/$card_name/240p/$renamed_file";
	}
		
	my $src_ip = '216.177.0.43';
	my $src_path = $file;
	my $job_status = 'ready';
	my $proc_host = 'unknown';

	print ("Inserting DB job: ", join('||', $event_name, $card_name, $src_ip, $file, $dst_path, $job_type, $job_status, $proc_host, $file_bytes), "\n") if DEBUG;

	my $sth = $dbh->prepare("INSERT INTO $db_table (event_name, card_name, src_ip, src_path, dst_path, job_type, job_status, proc_host, file_size) values (?,?,?,?,?,?,?,?,?)");

	$sth->execute($event_name, $card_name, $src_ip, $file, $dst_path, $job_type, $job_status, $proc_host, $file_bytes);
	
	return 1;
}

sub status_report {
	my $sth = $dbh->prepare("select count(job_id) as cnt from jobs where job_type = 'copy_lrv' and job_status != 'complete';");
	$sth->execute();
	while (my $ref = $sth->fetchrow_hashref()) {
		print ("LRV Jobs in Queue: ", $ref->{'cnt'}, " Jobs\n");
	}
	$sth->finish();
	
	$sth = $dbh->prepare("select count(job_id) as cnt from jobs where job_type = 'transcode_mp4' and job_status != 'complete';");
	$sth->execute();
	while (my $ref = $sth->fetchrow_hashref()) {
		print ("MP4 Jobs in Queue: ", $ref->{'cnt'}, " Jobs\n");
	}
	$sth->finish();

	return 1;
}

sub usage_and_die {
	print "Error in command options. go-roadrunner requires some arguements:\n";
	print " -c | --db_config_file: A config file, defaults to '/usr/local/fleye/roadrunner/etc/db.conf'\n";
	print " -l | --local_path_glob: For testing: A pattern to glob local paths from. E.X. '/local-'\n";
	print " -m | --mount_cards: Mount cards and look for files on attached card readers\n";
	print " -u | --unmount_cards: Umount all cards. Checks to make sure no jobs are running.\n";
	print " -t | --truncate_jobs: Truncates the jobs table; stops all processing. Checks to make sure no jobs are running.\n";
	print " -f | --force: Combine with -u or -t; forcefully unmount or truncate.\n";
	print " -s | --status_report: Prints a quick status report.\n";
	print " -h | --help: Prints this help.\n";
	print "By default, a status report is printed if no arguments are supplied.\n";
	exit;
}

