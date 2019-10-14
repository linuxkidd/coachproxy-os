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

# Control vent fan on/off status

use strict;
no strict 'refs';

our $debug = 0;

our %commands = (2 => 'on', 3 => 'off');

if (scalar(@ARGV) < 2) {
  print "ERR: Insufficient command line data provided.\n";
  usage();
}

our $command = $ARGV[0];
if (!exists($commands{$command})) {
  print "ERR: Command not allowed. Please see command list below.\n";
  usage();
}

our $load = $ARGV[1];

our ($prio, $dgnhi, $dgnlo, $srcAD) = (6, '1FE', 'DB', 96);
our $binCanId = sprintf("%b0%b%b%b", hex($prio), hex($dgnhi), hex($dgnlo), hex($srcAD));
our $hexCanId = sprintf("%08X", oct("0b$binCanId"));
our $hexData;

$hexData = sprintf("%02XFFC8%02X%02X00FFFF", $load, $command, 255);
system('cansend can0 '.$hexCanId."#".$hexData) if (!$debug);
print 'cansend can0 '.$hexCanId."#".$hexData . "\n" if($debug);

sub usage {
  print "Usage: \n";

  print "\t$0 <command> <fan-id>\n";

  print "\n\t<command> is required and one of:\n";
  foreach my $key ( keys %commands ) {
    print "\t\t".$key." = ".$commands{$key}."\n";
  }

  print "\n\t<fan-id> is required and is a valid Spyder load ID\n";

  print "\n";
  exit(1);
}
