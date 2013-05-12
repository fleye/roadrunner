#!/usr/bin/perl

use strict;
use warnings;

use CGI;
use DBD::mysql;

my $cgi = CGI->new;

my $db_host = 'localhost';
my $db_user = 'roadrunner';
my $db_pass = '6rg2WMP9uulYkhE4-87A';
my $db_name = 'fleye_roadrunner';
my $db_table = 'config';

my $dbh = DBI->connect(
	"DBI:mysql:database=$db_name;host=$db_host",
	"$db_user",
	"$db_pass",
  {'RaiseError' => 1}
) || die "Could not connect to database\n";

print $cgi->header();

print $cgi->start_html('Roadrunner Configuration');

print $cgi->h1('Roadrunner Configuration');

print "<table border='2'>\n";
print "<tr>\n";
print "<th>ID</th><th>Name</th><th>Value</th>\n";
print "</tr>\n";

my $sth = $dbh->prepare("SELECT * FROM $db_table");
$sth->execute();
while (my $ref = $sth->fetchrow_hashref()) {
	print "<tr>\n";
	print "<td>\n";
	print $ref->{'config_id'};
	print "</td>\n";
	print "<td>\n";
	print $ref->{'name'};
	print "</td>\n";
	print "<td>\n";
	print $ref->{'value'};
	print "</td>\n";
	print "</tr>\n";
}
$sth->finish();

$cgi->end_html;

$dbh->disconnect();
  
