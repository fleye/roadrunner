#!/usr/bin/perl

use strict;
use warnings;

use constant DEBUG => 1;

use Data::Dumper;
use Config::General;
use Cwd;
use Digest::MD5 qw(md5_hex);
use Gearman::Client;
use Storable qw(freeze);

# Read in configuration block
my $conf = new Config::General("/usr/local/fleye/transcoder/go-fleye.conf");
my %config = $conf->getall;

print "Configuration Dump:\n" if DEBUG;
print Dumper %config if DEBUG;

# Connect out to Gearmand
my $gearmand = Gearman::Client->new();
my $server = $config{'ingest_gearmand'};
$gearmand->job_servers($server) || die "Didn't connect to gearmand\n";

print Dumper $gearmand;

# Locate the current working directory, which should be a mounted SDXC card, and generate an MD5 of the path.
my $cwd = getcwd();
my $dir_md5 = md5_hex($cwd . time());

print "Working Dir: $cwd\n" if DEBUG;
print "MD5 Dir: $dir_md5\n" if DEBUG;

# Find all of the LRV files, and create a hash of the files and their remote files names (which includes created time)

my %lrv_files;

$lrv_files{'scp_host'} = $config{'ingest_scp'};
$lrv_files{'src_path'} = $cwd;
$lrv_files{'storage_path'} = $config{'storage_path'};
$lrv_files{'card_id'} = $dir_md5;

my @lrv_files = glob("*.LRV");

foreach my $lrv (sort @lrv_files) {
	my $file_ctime_epoch = (stat($lrv))[10];
	my @ctime = localtime($file_ctime_epoch);
	
	my $ctime_year = $ctime[5]+1900;
	my $ctime_month = sprintf("%02d", $ctime[4]+1);
	my $ctime_day = sprintf("%02d", $ctime[3]);
	my $ctime_hour = sprintf("%02d", $ctime[2]);
	my $ctime_min = sprintf("%02d", $ctime[1]);
	my $ctime_sec = sprintf("%02d", $ctime[0]);
	
	my ($base) = split(/\./, $lrv);
	
	my $renamed_file = "$base-$ctime_year-$ctime_month-$ctime_day-$ctime_hour-$ctime_min-$ctime_sec-240p.mp4";
	
	$lrv_files{$lrv} = $renamed_file;
	
}

print "Showing LRV files\n" if DEBUG;
print Dumper %lrv_files if DEBUG;

my $args = freeze \%lrv_files;

my $task = Gearman::Task->new("copy_lrv", \$args, {
	high_priority => 1,
	});
	
$gearmand->dispatch_background($task);

sleep 10;

# Find all of the MP4 files, and create a hash of the files and their remote files names (which includes created time)

my %mp4_files;

$mp4_files{'scp_host'} = $config{'ingest_scp'};
$mp4_files{'src_path'} = $cwd;
$mp4_files{'storage_path'} = $config{'storage_path'};
$mp4_files{'card_id'} = $dir_md5;

my @mp4_files = glob("*.MP4");

foreach my $mp4 (sort @mp4_files) {
	my $file_ctime_epoch = (stat($mp4))[10];
	my @ctime = localtime($file_ctime_epoch);
	
	my $ctime_year = $ctime[5]+1900;
	my $ctime_month = sprintf("%02d", $ctime[4]+1);
	my $ctime_day = sprintf("%02d", $ctime[3]);
	my $ctime_hour = sprintf("%02d", $ctime[2]);
	my $ctime_min = sprintf("%02d", $ctime[1]);
	my $ctime_sec = sprintf("%02d", $ctime[0]);
	
	my ($base) = split(/\./, $mp4);
	
	my $renamed_file = "$base-$ctime_year-$ctime_month-$ctime_day-$ctime_hour-$ctime_min-$ctime_sec-1080p.mp4";
	
	$mp4_files{$mp4} = $renamed_file;
	
}

print "Showing MP4 files\n" if DEBUG;
print Dumper %mp4_files if DEBUG;

my $args = freeze \%mp4_files;

my $task = Gearman::Task->new("transcode_1080p_360p", \$args, {
	});
	
$gearmand->dispatch_background($task);


