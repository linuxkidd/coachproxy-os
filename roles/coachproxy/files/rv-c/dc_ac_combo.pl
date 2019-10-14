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

# dc_ac_combo.pl
#
# Send an on or off command (2 or 3) to both a DC and an AC system at the same
# time. This is used 2018+ Tiffins which use both a DC_DIMMER_COMMAND_2 and an
# AC_LOAD_COMMAND to control the electric side of the AquaHot. This script
# simply calls the corresponding dc_dimmer.pl and ac_load.pl scripts with the
# provided load IDs and command.

use strict;
no strict 'refs';

our %commands = (2 => 'On (Delay)' , 3 => 'Off (Delay)');

if ( scalar(@ARGV) < 3 ) {
	print "ERR: Insufficient command line data provided.\n";
	usage();
}

our ($dc_instance, $ac_instance, $command) = ($ARGV[0], $ARGV[1], $ARGV[2]);

system("/coachproxy/rv-c/dc_dimmer.pl $dc_instance $command");
system("/coachproxy/rv-c/ac_load.pl $ac_instance $command");


sub usage {
	print "Usage: \n";
	print "\tdc_ac_combo.pl <dc-load-id> <ac-load-id> <command>\n";
	print "\n\t<command> is required and one of:\n";
	foreach my $key ( sort {$a <=> $b} keys %commands ) {
		print "\t\t".$key." = ".$commands{$key} . "\n";
	}
	print "\n";
	exit(1);
}
