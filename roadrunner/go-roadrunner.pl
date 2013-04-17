#!/usr/bin/perl

# go-roadrunner will find all SDXC cards mounted on a box, find all MP4 or LRV files on the cards, and queue them into the database for processing by the encoding machines.

use strict;
use warnings;

use File::Util;

my $mount_card = 0;
my $event_name = 'default';

# Find and mount cards.
# Walk through contents of card, finding LRV and MP4 files.
# Insert entries into the database.

my $f = File::Util->new();

foreach my $letter ('f'..'s') {
	my $device = "sd";
	$device .= $letter;
	print "Checking for device: $device\n";
	
	if (-e "/dev/$device") {
		print "Found device: $device - enumerating all slices by false mount.\n";
		
		system("/bin/mount -f /dev/$device");
		
		my $devnode = $device;
		$devnode .= '1';
		
		if (-e "/dev/$devnode") {
			print "Found devnode: $devnode - checking for card directory.\n";
		
			my $carddir = "/card-$devnode";
		
			unless (-e $carddir) {
				print "Cannot find card directory - creating...\n";
				system("mkdir $carddir");
			}
			
			print "Ready to attempt exfat mount of $devnode to $carddir";
			if ($mount_card) {
				system("/usr/sbin/mount.exfat /dev/$devnode $carddir")
			}
			
			print "Card mounted. Locating files.\n";
			my @card_files = $f->list_dir("$carddir", '--recurse');
			
			foreach my $file (@card_files) {
				if ($file =~ /\.LRV$/i) {
					print "Found LRV file: $file\n";
				} elsif ($file =~ /\.MP4$/i) {
					print "Found MP4 file: $file\n";
				} else {
					next;
				}
			}
		}
		
		print "Did not find a slice on card to mount\n";
	}
	
	print "Did not find a device by letter...next please.\n";
}

print "Mounted devices:\n";
system("/bin/mount");

