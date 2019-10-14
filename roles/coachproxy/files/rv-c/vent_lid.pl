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

# Control vent lid up/down status

use strict;
no strict 'refs';

our $debug = 0;

our %commands = (69 => 'up', 133 => 'down');

if (scalar(@ARGV) < 3) {
  print "ERR: Insufficient command line data provided.\n";
  usage();
}

our $command = $ARGV[0];
if (!exists($commands{$command})) {
  print "ERR: Command not allowed. Please see command list below.\n";
  usage();
}

our $load_up = $ARGV[1];
our $load_down = $ARGV[2];
our $indicator = $ARGV[3];

our @instances = ($load_up, $load_down);
@instances = reverse @instances if ($command == 133);

our ($prio, $dgnhi, $dgnlo, $srcAD) = (6, '1FE', 'DB', 96);
our $binCanId=sprintf("%b0%b%b%b",hex($prio),hex($dgnhi),hex($dgnlo),hex($srcAD));
our $hexCanId=sprintf("%08X",oct("0b$binCanId"));
our $hexData;

# Stop the 'Anti' instance
$hexData = sprintf("%02XFF00%02X%02X00FFFF", $instances[1], 3, 0);
system('cansend can0 '.$hexCanId."#".$hexData) if (!$debug);
print 'cansend can0 '.$hexCanId."#".$hexData . "\n" if($debug);

# Engage the instance
$hexData = sprintf("%02XFFC8%02X%02X00FFFF", $instances[0], 1, 20);
system('cansend can0 '.$hexCanId."#".$hexData) if (!$debug);
print 'cansend can0 '.$hexCanId."#".$hexData . "\n" if($debug);

# Set the indicator if present (pre-2018 coaches)
if ($indicator) {
  our %status = (69 => 3, 133 => 2);
  $dgnlo = 'D9';
  $binCanId = sprintf("%b0%b%b%b", hex($prio), hex($dgnhi), hex($dgnlo), hex($srcAD));
  $hexCanId = sprintf("%08X", oct("0b$binCanId"));
  $hexData  = sprintf("%02Xff00ffffff%02Xff", $indicator, $status{$command});
  system('cansend can0 '.$hexCanId."#".$hexData) if (!$debug);
  print 'cansend can0 '.$hexCanId."#".$hexData . "\n" if($debug);
}

sub usage {
  print "Usage: \n";

  print "\t$0 <command> <lid-up-id> <lid-down-id> <lid-indicator-id>\n";

  print "\n\t<command> is required and one of:\n";
  foreach my $key ( keys %commands ) {
    print "\t\t".$key." = ".$commands{$key}."\n";
  }

  print "\n\t<lid-up-id> is required and is a valid Spyder load ID\n";
  print "\n\t<lid-down-id> is required and is a valid Spyder load ID\n";
  print "\n\t<lid-indicator-id> is optional and is a valid Spyder load ID\n";

  print "\n";
  exit(1);
}
