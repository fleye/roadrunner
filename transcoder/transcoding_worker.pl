#!/usr/bin/perl

use strict;
use warnings;

use Gearman::Worker;
use Storable qw (thaw);
use File::Temp qw(tmpnam);
use Data::Dumper;

my $worker = Gearman::Worker->new();

$worker->job_servers('127.0.0.1:4730') || die "Could not connect to job server\n";

$worker->register_function(
	process_card => \&process_card
);

$worker->register_function(
	copy_lrv => \&copy_lrv
);

$worker->register_function(
	transcode_1080p_360p => \&transcode_1080p_360p
);

$worker->work while 1;

sub process_card {
	print "Received process_card job.\n";
	my %args = %{thaw($_[0]->arg)};
	print Dumper %args;

	my $storage_path = $args{'storage_path'};
	my $card_id = $args{'card_id'};
	
	system("mkdir $storage_path\/$card_id");
	system("mkdir $storage_path\/$card_id\/240p");
	system("mkdir $storage_path\/$card_id\/360p");
	system("mkdir $storage_path\/$card_id\/1080p");	
}


sub copy_lrv {
	print "Received copy_lrv job.\n";
	my %args = %{thaw($_[0]->arg)};
	print Dumper %args;

	my $remote_hostname = delete $args{'hostname'};
	my $src_path = delete $args{'src_path'};
	my $storage_path = delete $args{'storage_path'};
	my $card_id = delete $args{'card_id'};
	my $scp_key = delete $args{'scp_key'};
	
	my $scp_file = tmpnam();
	open (SCP, ">$scp_file");
	print SCP "$scp_key\n";
	close SCP;
	chmod (0600, $scp_file);
			
	foreach my $lrv (sort keys %args){
		next unless $lrv =~ m/.+\.lrv/;
		my $dst_file = $args{$lrv};

		print "Copying from $remote_hostname $src_path $lrv to $storage_path $card_id 240p $dst_file\n";
		system("/usr/bin/scp -i $scp_file ec2-user\@$remote_hostname\:$src_path\/$lrv $storage_path\/$card_id\/240p\/$dst_file");
	}

	unlink $scp_file;

	return 1;
}

sub transcode_1080p_360p {
	print "Received transcode_1080p_360p job.\n";
	my %args = %{thaw($_[0]->arg)};
	print Dumper %args;

	my $remote_hostname = delete $args{'hostname'};
	my $src_path = delete $args{'src_path'};
	my $storage_path = delete $args{'storage_path'};
	my $card_id = delete $args{'card_id'};
	my $scp_key = delete $args{'scp_key'};

	my $scp_file = tmpnam();
	open (SCP, ">$scp_file");
	print SCP "$scp_key\n";
	close SCP;
	chmod (0600, $scp_file);
	
	foreach my $mp4 (sort keys %args){
		next unless $mp4 =~ m/.+\.mp4/;
		my $dst_file = $args{$mp4};

		print "Copying from $remote_hostname $src_path $mp4 to $storage_path $card_id 1080p $dst_file\n";
		system("/usr/bin/scp -i $scp_file ec2-user\@$remote_hostname\:$src_path\/$mp4 $storage_path\/$card_id\/1080p\/$dst_file");	
			
		print "Asynchronously kicking off transcoding job\n";
		system("cp $storage_path\/$card_id\/1080p\/$dst_file $storage_path\/$card_id\/360p\/$dst_file")
		}
		
		unlink $scp_file;

		return 1;
}
