#!/usr/bin/perl

use strict;
use warnings;

use File::Util;

use DBI;
use DBD::mysql;
use Digest::MD5 qw(md5_hex);

use Getopt::Long;

# options
-- stop_worker (hostname or ALL)
-- start_worker (hostname or ALL)
-- stop_event (name or ALL)
-- start_event (name or ALL)
-- start_card (name or ALL)
-- stop_card (name or ALL)

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
