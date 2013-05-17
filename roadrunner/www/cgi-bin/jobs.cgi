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
my $db_table = 'jobs';

my $dbh = DBI->connect(
	"DBI:mysql:database=$db_name;host=$db_host",
	"$db_user",
	"$db_pass",
  {'RaiseError' => 1}
) || die "Could not connect to database\n";

print $cgi->header();

print $cgi->start_html('Fleye Job Status');

print $cgi->h1('Fleye - Roadrunner Job Status');

my $datetime = scalar localtime();

print $cgi->h3("Last Updated: $datetime");

print $cgi->h3("Active Jobs");

print "<table border='2'>\n";
print "<tr>\n";
print "<th>Job ID</th><th>Event Name</th><th>Card Name</th><th>Source IP</th><th>Source Path</th><th>Destination Path</th><th>Job Type</th><th>Job Status</th><th>Processing Host</th><th>File Size</th><th>Network Time</th><th>Encoding Time</th><th>Last Modified</th>\n";
print "</tr>\n";

my $sth = $dbh->prepare("SELECT * FROM $db_table WHERE job_status NOT IN ('ready', 'complete')");
$sth->execute();
while (my $ref = $sth->fetchrow_hashref()) {
	print "<tr>\n";
	print "<td>\n";
	print $ref->{'job_id'};
	print "</td>\n";
	print "<td>\n";
	print $ref->{'event_name'};
	print "</td>\n";
	print "<td>\n";
	print $ref->{'card_name'};
	print "</td>\n";
	print "<td>\n";
	print $ref->{'src_ip'};
	print "</td>\n";
	print "<td>\n";
	print $ref->{'src_path'};
	print "</td>\n";
	print "<td>\n";
	print $ref->{'dst_path'};
	print "</td>\n";
	print "<td>\n";
	print $ref->{'job_type'};
	print "</td>\n";
	print "<td>\n";
	print $ref->{'job_status'};
	print "</td>\n";
	print "<td>\n";
	print $ref->{'proc_host'};
	print "</td>\n";
	print "<td>\n";
	print $ref->{'file_size'};
	print "</td>\n";
	print "<td>\n";
	print $ref->{'network_time'};
	print "</td>\n";
	print "<td>\n";
	print $ref->{'encode_time'};
	print "</td>\n";
	print "<td>\n";
	print $ref->{'modified'};
	print "</td>\n";
	print "</tr>\n";
}
$sth->finish();

print "</table>";

print $cgi->h3("Queued Jobs");

print "<table border='2'>\n";
print "<tr>\n";
print "<th>Job ID</th><th>Event Name</th><th>Card Name</th><th>Source IP</th><th>Source Path</th><th>Destination Path</th><th>Job Type</th><th>Job Status</th><th>Processing Host</th><th>File Size</th><th>Network Time</th><th>Encoding Time</th><th>Last Modified</th>\n";
print "</tr>\n";

my $sth = $dbh->prepare("SELECT * FROM $db_table WHERE job_status = 'ready'");
$sth->execute();
while (my $ref = $sth->fetchrow_hashref()) {
	print "<tr>\n";
	print "<td>\n";
	print $ref->{'job_id'};
	print "</td>\n";
	print "<td>\n";
	print $ref->{'event_name'};
	print "</td>\n";
	print "<td>\n";
	print $ref->{'card_name'};
	print "</td>\n";
	print "<td>\n";
	print $ref->{'src_ip'};
	print "</td>\n";
	print "<td>\n";
	print $ref->{'src_path'};
	print "</td>\n";
	print "<td>\n";
	print $ref->{'dst_path'};
	print "</td>\n";
	print "<td>\n";
	print $ref->{'job_type'};
	print "</td>\n";
	print "<td>\n";
	print $ref->{'job_status'};
	print "</td>\n";
	print "<td>\n";
	print $ref->{'proc_host'};
	print "</td>\n";
	print "<td>\n";
	print $ref->{'file_size'};
	print "</td>\n";
	print "<td>\n";
	print $ref->{'network_time'};
	print "</td>\n";
	print "<td>\n";
	print $ref->{'encode_time'};
	print "</td>\n";
	print "<td>\n";
	print $ref->{'modified'};
	print "</td>\n";
	print "</tr>\n";
}
$sth->finish();

print "</table>";

print $cgi->h3("Completed Jobs");

print "<table border='2'>\n";
print "<tr>\n";
print "<th>Job ID</th><th>Event Name</th><th>Card Name</th><th>Source IP</th><th>Source Path</th><th>Destination Path</th><th>Job Type</th><th>Job Status</th><th>Processing Host</th><th>File Size</th><th>Network Time</th><th>Encoding Time</th><th>Last Modified</th>\n";
print "</tr>\n";

my $sth = $dbh->prepare("SELECT * FROM $db_table WHERE job_status = 'complete'");
$sth->execute();
while (my $ref = $sth->fetchrow_hashref()) {
	print "<tr>\n";
	print "<td>\n";
	print $ref->{'job_id'};
	print "</td>\n";
	print "<td>\n";
	print $ref->{'event_name'};
	print "</td>\n";
	print "<td>\n";
	print $ref->{'card_name'};
	print "</td>\n";
	print "<td>\n";
	print $ref->{'src_ip'};
	print "</td>\n";
	print "<td>\n";
	print $ref->{'src_path'};
	print "</td>\n";
	print "<td>\n";
	print $ref->{'dst_path'};
	print "</td>\n";
	print "<td>\n";
	print $ref->{'job_type'};
	print "</td>\n";
	print "<td>\n";
	print $ref->{'job_status'};
	print "</td>\n";
	print "<td>\n";
	print $ref->{'proc_host'};
	print "</td>\n";
	print "<td>\n";
	print $ref->{'file_size'};
	print "</td>\n";
	print "<td>\n";
	print $ref->{'network_time'};
	print "</td>\n";
	print "<td>\n";
	print $ref->{'encode_time'};
	print "</td>\n";
	print "<td>\n";
	print $ref->{'modified'};
	print "</td>\n";
	print "</tr>\n";
}
$sth->finish();

print "</table>";

$cgi->end_html;

$dbh->disconnect();
  
