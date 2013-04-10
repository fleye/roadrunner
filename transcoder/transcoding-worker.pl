#!/usr/bin/perl

use strict;
use warnings;

use Gearman::Worker;
use Storable qw (thaw);
use File::Temp qw(tmpnam);
use Data::Dumper;

my $worker = Gearman::Worker->new();

$worker->job_servers('216.177.0.43:4730') || die "Could not connect to job server\n";

$worker->register_function(
	copy_lrv => \&copy_lrv
);

$worker->register_function(
	transcode_1080p_360p => \&transcode_1080p_360p
);

$worker->work while 1;

sub copy_lrv {
	print "Received copy_lrv job.\n";
	my %args = %{thaw($_[0]->arg)};
	print Dumper %args;

	my $scp_hostname = delete $args{'scp_host'};
	my $src_path = delete $args{'src_path'};
	my $storage_path = delete $args{'storage_path'};
	my $card_id = delete $args{'card_id'};

	unless (-e "$storage_path\/$card_id") {
		system("mkdir $storage_path\/$card_id");
	}

	unless (-e "$storage_path\/$card_id\/240p") {
		system("mkdir $storage_path\/$card_id\/240p");
	}

	foreach my $lrv (sort keys %args){
		next unless $lrv =~ m/.+\.LRV/;
		my $dst_file = $args{$lrv};

		print "Copying from $scp_hostname $src_path $lrv to $storage_path $card_id 240p $dst_file\n";
		system("/usr/bin/scp -l 100000 system\@$scp_hostname\:$src_path\/$lrv $storage_path\/$card_id\/240p\/$dst_file");
	}

	return 1;
}

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
			
		print "Asynchronously kicking off transcoding job\n";

# ffmpeg -vf scale=640:360 -crf 25.0 -vcodec libx264 -acodec libvo_aacenc -ar 48000 -b:a 128k -coder 1 -rc_lookahead 60 -threads 0 -i 1080p 20130324081942_GOPR0001-2013-03-24-08-32-58-1080p.mp4 360p/20130324081942_GOPR0001-2013-03-24-08-32-58-360p.mp4 



# 		system("cp $storage_path\/$card_id\/1080p\/$dst_file $storage_path\/$card_id\/360p\/$dst_file")
	}
		
	return 1;
}
