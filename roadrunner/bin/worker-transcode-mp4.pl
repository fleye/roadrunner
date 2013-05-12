#!/usr/bin/perl

use strict;
use warnings;

use File::Temp qw(tmpnam);
use Data::Dumper;

use DBI;
use DBD::mysql;

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
);

# Connect to the Database

# Register myself as a worker

# Daemonize

# Job Loop

sub transcode_1080p_360p {
	print "Received transcode_1080p_360p job.\n";
	my %args = %{thaw($_[0]->arg)};
	print Dumper %args;

	my $scp_hostname = delete $args{'scp_host'};
	my $src_path = delete $args{'src_path'};
	my $storage_path = delete $args{'storage_path'};
	my $card_id = delete $args{'card_id'};

	unless (-e "$storage_path\/$card_id") {
		system("mkdir $storage_path\/$card_id");
	}

	unless (-e "$storage_path\/$card_id\/360p") {
		system("mkdir $storage_path\/$card_id\/360p");
	}

	unless (-e "$storage_path\/$card_id\/1080p") {
		system("mkdir $storage_path\/$card_id\/1080p");
	}

	foreach my $mp4 (sort keys %args){
		next unless $mp4 =~ m/.+\.MP4/;
		my $dst_file = $args{$mp4};

		print "Copying from $scp_hostname $src_path $mp4 to $storage_path $card_id 1080p $dst_file\n";
		system("/usr/bin/scp -l 100000 system\@$scp_hostname\:$src_path\/$mp4 $storage_path\/$card_id\/1080p\/$dst_file");	
			
		print "Checking for running ffmpeg job.\n";

		while  (qx/pgrep ffmpeg/) {
			print "FFmpeg process is running, blocking and sleeping 60 seconds.\n";
			sleep 60;
		}

		print "Kicking off FFmpeg asynchrounously. Look for screen.\n";
		system("/usr/bin/screen -d -m /usr/bin/ffmpeg -i $storage_path\/$card_id\/1080p\/$dst_file -vf scale=640:360 -crf 25.0 -vcodec libx264 -acodec libvo_aacenc -ar 48000 -b:a 128k -coder 1 -rc_lookahead 60 -threads 0 -y $storage_path\/$card_id\/360p\/$dst_file");
	}
		
	return 1;
}
