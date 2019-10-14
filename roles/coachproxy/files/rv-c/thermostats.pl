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

# Thermostat control was added in the 2018 Phaeton and above.

use strict;
no strict 'refs';
use Switch

our $debug = 0;

our %commands = (
  'off' => 'Off',
  'cool' => 'A/C On',
  'heat' => 'Heat On',
  'low' => 'Fan Low',
  'high' => 'Fan High',
  'auto' => 'Fan Auto',
  'up' => 'Temp Up',
  'down' => 'Temp Down',
  'set' => 'Set Temp To...',
);

our %thermostat_commands = (
  'off'  => 'C0FFFFFFFFFFFF',
  'cool' => 'C1FFFFFFFFFFFF',
  'heat' => 'C2FFFFFFFFFFFF',
  'low'  => 'DF64FFFFFFFFFF',
  'high' => 'DFC8FFFFFFFFFF',
  'auto' => 'CFFFFFFFFFFFFF',
  'low_fanonly'  => 'D464FFFFFFFFFF',
  'high_fanonly' => 'D4C8FFFFFFFFFF',
  'auto_fanonly' => 'C0FFFFFFFFFFFF',
  'up'   => 'FFFFFFFFFAFFFF',
  'down' => 'FFFFFFFFF9FFFF',
);

if (scalar(@ARGV) < 2) {
	print "ERROR: Too few command line arguments provided.\n";
	usage();
}

our $instance = $ARGV[0];
if ($instance < 0 or $instance > 6) {
	print "ERROR: Invalid zone specified.\n";
	usage();
}

our $command = $ARGV[1];
if (!exists($commands{$command})) {
	print "ERROR: Invalid command specified.\n";
	usage();
}

# When controlling the fans, slightly different commands need to be sent
# depending on whether the "mode" is already set to something like A/C or
# not.
if (scalar(@ARGV) >= 3) {
  our $current_mode = $ARGV[2];
  if (grep(/^$command$/, ('low', 'high', 'auto')) and grep(/^$current_mode$/, ('off', 'fan'))) {
    $command .= '_fanonly';
  }
}

our ($prio, $dgnhi, $dgnlo, $srcAD) = (6, '1FE', 'F9', 99);

our $binCanId = sprintf("%b0%b%b%b", hex($prio), hex($dgnhi), hex($dgnlo), hex($srcAD));
our $hexCanId = sprintf("%08X", oct("0b$binCanId"));

our $hexData;

# Send THERMOSTAT_COMMAND.
if ($thermostat_commands{$command}) {
  $hexData = sprintf("%02X%s", $instance, $thermostat_commands{$command});
  cansend($hexCanId, $hexData);
}

# Send setpoint commands
if ($command eq 'set') {
  if (exists($ARGV[2])) {
    # Spyder uses 75.5, 76.5, 77.5, etc. so we need to add 0.5
    my $tempRVC = tempF2hex($ARGV[2] + 0.5);
    $hexData = sprintf("%02XFFFF%s%sFF", $instance, $tempRVC, $tempRVC);
    cansend($hexCanId, $hexData);

    # Also set the furnace setpoints, if available. So far, only zones 0 and 2 (RED)
    # or 2 and 4 (Phaeton+) have furnaces available.
    if ($instance % 2 == 0) {
      $hexData = sprintf("%02XFFFF%s%sFF", $instance + 3, $tempRVC, $tempRVC);
      cansend($hexCanId, $hexData);
    }
  }
}

exit;

# Add 0.999 to perform a ceil() function on the resulting value to prevent
# rounding errors. E.g. 71 F normally translates to 9429.33333 or 24D5 hex.
# However, 24D5 translates back to 70.98125 F, causing the Spyder screen to
# display 70 instead of 71.
sub tempF2hex {
	my ($data)=@_;
	my $hexchars=sprintf("%04X",(((($data-32)*5/9)+273)/0.03125)+0.999);
	my @binarray= $hexchars =~ m/(..?)/sg;
	return $binarray[1].$binarray[0];
}


sub cansend {
  our $debug;
  my ($id, $data) = @_;
  system('cansend can0 ' . $id . "#" . $data) if (!$debug);
  print 'cansend can0 '. $id . "#" . $data . "\n" if ($debug);
}


sub usage {
	print "Usage: \n";
	print "\t$0 <zone> <command>\n";
	print "\n\tZones:\n";
  print "\t\tHighline coaches: 2=Front 3=Mid 4=Rear 5=Front Furnace 6=Rear Furnace\n";
  print "\t\tLowline coaches:  0=Front 1=Mid 2=Rear 3=Front Furnace 4=Rear Furnace\n";
	print "\n\tCommands:\n";
	foreach my $key ( keys %commands ) {
		print "\t\t" . $key . " = " . $commands{$key} . "\n";
	}
	print "\n";
	exit(1);
}
