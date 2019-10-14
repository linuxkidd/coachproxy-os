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

our %deccommands=(
	0=>'Off',1=>'Low',2=>'High',
);

if ( scalar(@ARGV) < 1 ) {
	print "ERR: Insufficient command line data provided.\n";
	usage();
}

if(!exists($deccommands{$ARGV[0]})) {
	print "ERR: Command not allowed.  Please see command list below.\n";
	usage();
}


our ($prio,$dgnhi,$dgnlo,$srcAD,$instance,$command)=(6,'1FE','DB',96,1,$ARGV[0]);
our ($hexData,$binCanId,$hexCanId)=(0,0,0);

our %specials=(
	1 => { 0 => [ 105, 106 ], 1=> [ 106, 105 ], 2 => [ 105, 106 ] },
);

if (exists($specials{$instance})) {
	$binCanId=sprintf("%b0%b%b%b",hex($prio),hex($dgnhi),hex($dgnlo),hex($srcAD));
	$hexCanId=sprintf("%08X",oct("0b$binCanId"));

	if($command > 0) {
		# Turn on master Elect On/Off
		$hexData=sprintf("%02XFFC8%02X%02X00FFFF",107,1,255);
		system('cansend can0 '.$hexCanId."#".$hexData) if (!$debug);
		print 'cansend can0 '.$hexCanId."#".$hexData . "\n" if($debug);

		# Turn off Anti-mode
		$hexData=sprintf("%02XFFC8%02X%02X00FFFF",$specials{$instance}{$command}[1],3,0);
		system('cansend can0 '.$hexCanId."#".$hexData) if (!$debug);
		print 'cansend can0 '.$hexCanId."#".$hexData . "\n" if($debug);

		# Turn on Desired Mode
		$hexData=sprintf("%02XFFC8%02X%02X00FFFF",$specials{$instance}{$command}[0],1,255);
		system('cansend can0 '.$hexCanId."#".$hexData) if (!$debug);
		print 'cansend can0 '.$hexCanId."#".$hexData . "\n" if($debug);
	} else {
		# Turn on master Elect On/Off
		$hexData=sprintf("%02XFFC8%02X%02X00FFFF",107,3,0);
		system('cansend can0 '.$hexCanId."#".$hexData) if (!$debug);
		print 'cansend can0 '.$hexCanId."#".$hexData . "\n" if($debug);

		$hexData=sprintf("%02XFFC8%02X%02X00FFFF",$specials{$instance}{$command}[0],3,0);
		system('cansend can0 '.$hexCanId."#".$hexData) if (!$debug);
		print 'cansend can0 '.$hexCanId."#".$hexData . "\n" if($debug);

		$hexData=sprintf("%02XFFC8%02X%02X00FFFF",$specials{$instance}{$command}[1],3,0);
		system('cansend can0 '.$hexCanId."#".$hexData) if (!$debug);
		print 'cansend can0 '.$hexCanId."#".$hexData . "\n" if($debug);
	}
}

sub usage {
	print "Usage: \n";
	print "\t$0 <command>\n";
	print "\n\t<command> is one of:\n";
	foreach my $key ( sort {$a <=> $b} keys %deccommands ) {
		print "\t\t".$key." = ".$deccommands{$key} . "\n";
	}
	print "\n";
	exit(1);
}
