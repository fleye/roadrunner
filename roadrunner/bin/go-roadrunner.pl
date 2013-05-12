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
use Data::Dumper;

use constant DEBUG => 1;

my $config_file = '../roadrunner.conf';
my $mount_start;
my $mount_end;
my $local_path_glob;

GetOptions("config_file|c=s" => \$config_file,
						"mount_start|s=s" => \$mount_start,
						"mount_end|e=s" => \$mount_end,
						"local_path_glob|l=s" => \$local_path_glob,
					) || usage_and_die();
						
unless (($mount_start && $mount_end) || $local_path_glob) {
		usage_and_die();
}

my $conf = new Config::General($config_file);
my %config = $conf->getall;

my $event_name = 'default'; # We specify an event name for tracking.

my $db_host = 'localhost';
my $db_user = 'roadrunner';
my $db_pass = '6rg2WMP9uulYkhE4-87A';
my $db_name = 'fleye_roadrunner';
my $db_table = 'jobs';

my $dbh = DBI->connect(
	"DBI:mysql:database=$db_name;host=$db_host",
	"$db_user",
	"$db_pass",
  {'RaiseError' => 1}
) || die "Could not connect to MySQL Server\n";

if ($mount_start) {
	die "Need mount_end argument. Aborting...\n" unless $mount_end;
}

if ($mount_end) {
	die "Need mount_start argument. Aborting...\n" unless $mount_start;
}

# Setup a global batch ID for this run.
my $rand = 100000 * rand();
my $rand_md5 = md5_hex($rand);
my $batch_id = substr(md5_hex($rand_md5), 0, 6);
print "go-roadrunner.pl global batch ID: $batch_id\n";

my @card_dirs;

my $local_card_path = $local_path_glob;

if ($local_card_path) {
	@card_dirs = glob("$local_card_path*");
	if (DEBUG) {
			print "Processing local card path glob. Found directories:\n";
			print join("\n", @card_dirs);
			print "\n\n";
	}
}

if ($mount_start && $mount_end) {
	my $mount_prefix = '/card';
	
	my @devices = ("$mount_start" .. "$mount_end");
	
	foreach my $device (@devices) {
		$device = "sd" . $device;
		
		print "Checking for device: $device\n";
	
		if (-e "/dev/$device") {
			print "Found device: $device - enumerating all slices by false mount.\n";
			system("/bin/mount -f /dev/$device");
		
			my $devnode = $device;
			$devnode .= '1';
		
			if (-e "/dev/$devnode") {
				print "Found devnode: $devnode - checking for corresponding card directory.\n";
		
				my $carddir = "/$mount_prefix-$devnode";
		
				unless (-e $carddir) {
					print "Cannot find card directory - creating...\n";
					system("mkdir $carddir");
			}
			
				print "Ready to attempt exfat mount of $devnode to $carddir";
				system("/usr/sbin/mount.exfat /dev/$devnode $carddir");

				print "Card mounted. Locating files.\n";
				push (@card_dirs, $carddir);
		}

	print "Mounted devices:\n";
	system("/bin/mount");

	}
} }

foreach my $dir (@card_dirs) {
	print "Working on directory: $dir\n" if DEBUG;
	my ($event_name, $card_name) = extract_manifest($dir);

	my @video_files = find_files($dir);

	foreach my $file (@video_files) {
		print "Processing file: $file\n" if DEBUG;
		create_job($event_name, $card_name, $file);
	}
}

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
	
	print "Found files: \n" if DEBUG;
	print Dumper @card_files if DEBUG;
	
	my @video_files;
	
	foreach my $file (@card_files) {
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

	my $dst_path = "/MOSS/$event_name/$card_name/$renamed_file";

	my $job_type;
	if ($extension eq 'MP4'){
		$job_type = 'transcode_mp4';
	} elsif ($extension eq 'LRV') {
		$job_type = 'copy_lrv';
	}
		
	my $src_ip = '216.177.0.43';
	my $src_path = $file;
	my $job_status = 'ready';
	my $proc_host = 'unknown';

	print ("Inserting DB job: ", join('||', $event_name, $card_name, $src_ip, $file, $dst_path, $job_type, $job_status, $proc_host), "\n") if DEBUG;

	my $sth = $dbh->prepare("INSERT INTO $db_table (event_name, card_name, src_ip, src_path, dst_path, job_type, job_status, proc_host) values (?,?,?,?,?,?,?,?)");

	$sth->execute($event_name, $card_name, $src_ip, $file, $dst_path, $job_type, $job_status, $proc_host);
	
	return 1;
}

sub usage_and_die {
	print "Error in command options. go-roadrunner requires some arguements:\n";
	print "\t -c | --config_file: A config file, defaults to 'roadrunner.conf'\n";
	print "\t -s | --mount_start: A starting device letter for mounting cards (requires '-e')\n";
	print "\t -e | --mount_end: An ending device letter for mounting cards (requires '-s')\n";
	print "\t -l | --local_path_glob: A pattern for which globbing should occur for locally available paths.\n";
	print "Requires -s/-e OR -l at a minimum.\n";
	exit;
}

