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

# For the 2018 Phaeton (and presumably other models), the electric water heater
# toggle requires both a DC_DIMMER_COMMAND and AC_LOAD_COMMAND.

use strict;
no strict 'refs';

our $debug=0;

our %deccommands=(1=>'On (Duration)',2=>'On (Delay)',3=>'Off (Delay)');

if ( scalar(@ARGV) < 2 ) {
  print "ERR: Insufficient command line data provided.\n";
  usage();
}

if(!exists($deccommands{$ARGV[1]})) {
  print "ERR: Command not allowed.  Please see command list below.\n";
  usage();
}

our ($prio,$dgnhi,$dgnlo,$srcAD,$instance,$command,$brightness)=(6,'1FF','BE',99,$ARGV[0],$ARGV[1],200);
$brightness=0 if ($command == 3);

our $binCanId=sprintf("%b0%b%b%b",hex($prio),hex($dgnhi),hex($dgnlo),hex($srcAD));
our $hexCanId=sprintf("%08X",oct("0b$binCanId"));
our $hexData=sprintf("%02XFF%02X8000000000",$instance,$brightness);

system('cansend can0 '.$hexCanId."#".$hexData) if (!$debug);
print 'cansend can0 '.$hexCanId."#".$hexData."\n" if ($debug);

sub usage {
  print "Usage: \n";
  print "\tac_load.pl <ac-load-id> <command>\n";
  print "\n\t<command> is required and one of:\n";
  foreach my $key ( sort {$a <=> $b} keys %deccommands ) {
    print "\t\t".$key." = ".$deccommands{$key} . "\n";
  }
  print "\n";
  exit(1);
}
