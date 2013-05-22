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


print $cgi->h3("System Vital Signs");

print "<table border='2' padding='2'>\n";
print "<tr>\n";
print "<th>Average Network Throughput per Encoder</th><th>Average FFMPEG Throughput per Encoder</th><th>Remaining LRV Jobs</th><th>Remaining MP4 Jobs</th><th>Bytes Remaining</th><th>Estimated Time Remaining</th><th>Percent Complete</th><th>Average LRV Copy Time</th><th>Average MP4 Copy Time</th><th>Average MP4 Encoding Time</th><th>Approx. Runtime Duration</th>\n";
print "<tr>\n";


my $sth = $dbh->prepare("select round(((avg(file_size)/avg(network_time))*8)/1000000, 4) as avg_throughput from jobs where job_status = 'complete';");
$sth->execute();
while (my $ref = $sth->fetchrow_hashref()) {
	print "<td>\n";
	print $ref->{'avg_throughput'};
	print " Mbps\n";
	print "</td>\n";
}
$sth->finish();

my $sth = $dbh->prepare("select round(((avg(file_size)/avg(encode_time))*8)/1000000, 4) as avg_throughput from jobs where job_status = 'complete' and job_type = 'transcode_mp4';");
$sth->execute();
while (my $ref = $sth->fetchrow_hashref()) {
	print "<td>\n";
	print $ref->{'avg_throughput'};
	print " Mbps\n";
	print "</td>\n";
}
$sth->finish();

my $sth = $dbh->prepare("select count(job_id) as cnt from jobs where job_type = 'copy_lrv' and job_status != 'complete';");
$sth->execute();
while (my $ref = $sth->fetchrow_hashref()) {
	print "<td>\n";
	print $ref->{'cnt'};
	print " Jobs\n";
	print "</td>\n";
}
$sth->finish();

my $sth = $dbh->prepare("select count(job_id) as cnt from jobs where job_type = 'transcode_mp4' and job_status != 'complete';");
$sth->execute();
while (my $ref = $sth->fetchrow_hashref()) {
	print "<td>\n";
	print $ref->{'cnt'};
	print " Jobs\n";
	print "</td>\n";
}
$sth->finish();

my $sth = $dbh->prepare("select round(sum(file_size) / 1000 / 1000 / 1000, 4) as size from jobs where job_status != 'complete';");
$sth->execute();
while (my $ref = $sth->fetchrow_hashref()) {
	print "<td>\n";
	print $ref->{'size'};
	print " GB\n";
	print "</td>\n";
}
$sth->finish();

my $sth = $dbh->prepare("select round((select sum(file_size) from jobs where job_status != 'complete') / (select avg(file_size)/avg(network_time) from jobs where job_status = 'complete') / count(distinct(proc_host)) / 60 / 60, 4) as time_remaining from jobs where job_status in ('copying', 'encoding');");
$sth->execute();
while (my $ref = $sth->fetchrow_hashref()) {
	print "<td>\n";
	print $ref->{'time_remaining'};
	print " Hours\n";
	print "</td>\n";
}
$sth->finish();

my $sth = $dbh->prepare("select round((select sum(file_size) from jobs where job_status = 'complete') / sum(file_size), 4) * 100 as pct from jobs;");
$sth->execute();
while (my $ref = $sth->fetchrow_hashref()) {
	print "<td>\n";
	print $ref->{'pct'};
	print " Percent\n";
	print "</td>\n";
}
$sth->finish();

my $sth = $dbh->prepare("select avg(network_time) as t from jobs where job_type = 'copy_lrv' and job_status = 'complete';");
$sth->execute();
while (my $ref = $sth->fetchrow_hashref()) {
	print "<td>\n";
	print $ref->{'t'};
	print " Seconds\n";
	print "</td>\n";
}
$sth->finish();

my $sth = $dbh->prepare("select avg(network_time) as t from jobs where job_type = 'transcode_mp4' and job_status = 'complete';");
$sth->execute();
while (my $ref = $sth->fetchrow_hashref()) {
	print "<td>\n";
	print $ref->{'t'};
	print " Seconds\n";
	print "</td>\n";
}
$sth->finish();

my $sth = $dbh->prepare("select avg(encode_time) as t from jobs where job_type = 'transcode_mp4' and job_status = 'complete';");
$sth->execute();
while (my $ref = $sth->fetchrow_hashref()) {
	print "<td>\n";
	print $ref->{'t'};
	print " Seconds\n";
	print "</td>\n";
}
$sth->finish();

my $sth = $dbh->prepare("select timediff(max(modified), min(modified)) as dur from jobs;");
$sth->execute();
while (my $ref = $sth->fetchrow_hashref()) {
	print "<td>\n";
	print $ref->{'dur'};
	print "\n";
	print "</td>\n";
}
$sth->finish();

print "</tr>\n";
print "</table>";

print $cgi->h3("Active Jobs");

print "<table border='2'>\n";
print "<tr>\n";
print "<th>Job ID</th><th>Event Name</th><th>Card Name</th><th>Source IP</th><th>Source Path</th><th>Destination Path</th><th>Job Type</th><th>Job Status</th><th>Processing Host</th><th>File Size</th><th>Network Time</th><th>Encoding Time</th><th>Last Modified</th>\n";
print "</tr>\n";

my $sth = $dbh->prepare("SELECT * FROM $db_table WHERE job_status NOT IN ('ready', 'complete') ORDER BY proc_host, job_type, job_status");
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

my $sth = $dbh->prepare("SELECT * FROM $db_table WHERE job_status = 'ready' ORDER BY job_id");
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

my $sth = $dbh->prepare("SELECT * FROM $db_table WHERE job_status = 'complete' ORDER BY job_id");
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
  
