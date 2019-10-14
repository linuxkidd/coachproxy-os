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
	126 => "All",
	129 => "Entry",
	131 => "Passenger Slide",
	132 => "Galley",
	136 => "Mid Bath",
	138 => "Hall",
	139 => "Bedroom",
	140 => "Rear Bath",
);

our %loads_2018=(
	126 => "All",
	129 => "Entry",
	131 => "Passenger Slide",
	132 => "Galley",
	133 => "Mid Bath",
	134 => "Rear Bath",
	135 => "Bedroom",
	144 => "Hall Screen",
  148 => "Bedroom Screen"
);

if ( scalar(@ARGV) < 2 ) {
	print "ERR: Insufficient command line data provided.\n";
	usage();
}

if($ARGV[1]<0 || $ARGV[1]>100 || $ARGV[1]=~/^[^0-9]$/) {
	print "ERR: Command not allowed.  Please see command list below.\n";
	usage();
}

our ($prio,$dgnhi,$dgnlo,$srcAD,$instance,$brightness)=(6,'1FE','D9',99,$ARGV[0],$ARGV[1]*2);

our $binCanId=sprintf("%b0%b%b%b",hex($prio),hex($dgnhi),hex($dgnlo),hex($srcAD));
our $hexCanId=sprintf("%08X",oct("0b$binCanId"));

# Set Level
our  $hexData=sprintf("FF%02X%02XFFFFFF00FF",$instance,$brightness);
system('cansend can0 '.$hexCanId."#".$hexData) if (!$debug);
print 'cansend can0 '.$hexCanId."#".$hexData . "\n" if($debug);

sub usage {
	print "Usage: \n";
	print "\t$0 <panel-id> <level>\n";
	print "\n\t<panel-id> is one of:\n";
	foreach my $key ( sort {$a <=> $b} keys %loads ) {
		print "\t\t".$key." = ".$loads{$key} . "\n";
	}
	print "\n\tFor 2018+, <panel-id> is one of:\n";
	foreach my $key ( sort {$a <=> $b} keys %loads_2018 ) {
		print "\t\t".$key." = ".$loads_2018{$key} . "\n";
	}
	print "\n\t<level> is brightness from 0 to 100 percent\n";
	print "\n";
	exit(1);
}
