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

# Daemonize

# Register myself as a worker


# Job Loop








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

