#!/usr/bin/perl -w
#
# Copyright (C) 2019 Wandertech LLC
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

use strict;
no strict 'refs';

our $debug=0;

our %loads=(
	0=>'All Doors',
	1=>'Entry Door',
	2=>'DS Cargo',
	3=>'PS Cargo',
#	4=>'Unknown',
#	5=>'Unknown',
	6=>'Cargo',
);

our %loops=(
	6=>[2,3],
);

our %deccommands=(0=>'Unlock',1=>'Lock');

if ( scalar(@ARGV) < 2 ) {
	print "ERR: Insufficient command line data provided.\n";
	usage();
}

if(!exists($loads{$ARGV[0]})) {
	print "ERR: Lock does not exist.  Please see lock list below.\n";
	usage();
}

if(!exists($deccommands{$ARGV[1]})) {
	print "ERR: Command not allowed.  Please see command list below.\n";
	usage();
}

our ($prio,$dgnhi,$dgnlo,$srcAD,$instance,$command)=(6,'1FE','E4',99,$ARGV[0],$ARGV[1]);

our $binCanId=sprintf("%b0%b%b%b",hex($prio),hex($dgnhi),hex($dgnlo),hex($srcAD));
our $hexCanId=sprintf("%08X",oct("0b$binCanId"));
our $hexData=sprintf("%02X%02XFFFFFFFFFFFF",$instance,$command);

if(exists($loops{$instance})) {
	for(our $i=0;our $inst=$loops{$instance}[$i];$i++) {
		$hexData=sprintf("%02X%02XFFFFFFFFFFFF",$inst,$command);
		system('cansend can0 '.$hexCanId."#".$hexData) if(!$debug);
		print 'cansend can0 '.$hexCanId."#".$hexData."\n" if($debug);
		sleep 2 if($i==0);
	}
} else {
	system('cansend can0 '.$hexCanId."#".$hexData) if(!$debug);
	print 'cansend can0 '.$hexCanId."#".$hexData."\n" if($debug);
}

sub usage {
	print "Usage: \n";
	print "\t$0 <lock-id> <command>\n";
	print "\n\t<lock-id> is one of:\n";
	foreach my $key ( sort {$a <=> $b} keys %loads ) {
		print "\t\t".$key." = ".$loads{$key} . "\n";
	}
	print "\n\t<command> is one of:\n";
	foreach my $key ( sort {$a <=> $b} keys %deccommands ) {
		print "\t\t".$key." = ".$deccommands{$key} . "\n";
	}
	print "\n";
	exit(1);
}
