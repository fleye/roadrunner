#!/usr/bin/perl

use strict;
use warnings;

use Gearman::Worker;
use Storable qw (thaw);
use List::Util qw (sum);

my $worker = Gearman::Worker->new();

$worker->job_servers('127.0.0.1:4730') || die "Could not connect to job server\n";

$worker->register_function(
	sum => sub {
		print "Received job to sum two numbers.\n";
		sum @{ thaw($_[0]->arg) }
	}
);

$worker->work while 1;

