#!/usr/bin/perl

use strict;
use warnings;

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
			system("/usr/sbin/mount.exfat /dev/$devnode $carddir")
		}
		
		print "Did not find a slice on card to mount\n";
	}
	
	print "Did not find a device by letter...next please.\n";
}

print "Mounted devices:\n";
system("/bin/mount");

