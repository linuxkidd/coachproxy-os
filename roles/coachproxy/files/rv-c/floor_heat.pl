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

#
# Control the heated floors on Tiffin motorhomes.
#
# Examples:
#   floor_heat.pl direct 0 75
#   floor_heat.pl updown2018 0 up 2
#

use strict;
no strict 'refs';

our $debug = 0;

our %methods = ('direct2015' => 1, 'direct2016' => 1, 'updown2017' => 1, 'updown2018' => 1);
our %floors = ( 0 => 'Front', 1 => 'Rear');

if ( scalar(@ARGV) < 3 ) {
  print "ERR: Insufficient command line data provided.\n";
  usage();
}

my $methodyear = $ARGV[0] // 'unknown';
if (!exists($methods{$methodyear})) {
	print "ERR: Unrecognized floor heat method.\n";
	usage();
}

our $method = substr($methodyear, 0, 6);
our $year = substr($methodyear, 6, 4);

our $floor = $ARGV[1] // -1;
if (!exists($floors{$floor})) {
  print "ERR: Unrecognized floor ID.\n";
  usage();
}

our $command = $ARGV[2];
if ($command eq 'off' or $command eq 'on') {
  onoff();
} elsif ($method eq 'direct') {
  floor_heat_direct();
} elsif (substr($method, 0, 6) eq 'updown') {
  floor_heat_indirect();
}

exit;


# This is the traditional floor_heat.pl code. It can directly set a temperature
# in a 40-104F range, or can set heat levels from 1-5. This is all done with
# THERMOSTAT_COMMAND_1 (1FEF9).
#
sub floor_heat_direct {
  our %commands = (1 => '72 °F', 2 => '80 °F', 3 => '88 °F', 4 => '96 °F', 5 => '104 °F');
  our %temps = (72 => 1, 80 => 2, 88 => 3, 96 => 4, 104 => 5);
  our @indicator = (14, 15);

  if (!exists($commands{$command}) && ($command < 32 || $command > 104)) {
    print "ERR: Invalid command. Please see command list below.\n";
    usage();
  }

  our %levels = (
    1 => [231, 36, 42],
    2 => [117, 37, 52],
    3 => [  3, 38, 62],
    4 => [145, 38, 72],
    5 => [ 32, 39, 82],
  );

  our ($prio, $dgnhi, $dgnlo, $srcAD) = (6, '1FE', 'F9', 99);
  our $binCanId = sprintf("%b0%b%b%b", hex($prio), hex($dgnhi), hex($dgnlo), hex($srcAD));
  our $hexCanId = sprintf("%08X", oct("0b$binCanId"));

  sub tempF2HEX {
    my ($data) = @_;
    my $hexchars = sprintf("%04X", ((($data-32)*5/9)+273)/0.03125);
    my @binarray = $hexchars =~ m/(..?)/sg;
    return $binarray[1].$binarray[0];
  }

  # Set Level
  my $hexData;
  if ($command < 6) {
    $hexData = sprintf("%02XFFFF%02X%02XFFFF00", $floor, $levels{$command}[0], $levels{$command}[1]);
  } else {
    $hexData = sprintf("%02XFFFF%sFFFF00", $floor, tempF2HEX($command));
  }
  system('cansend can0 '.$hexCanId."#".$hexData) if (!$debug);
  print 'cansend can0 '.$hexCanId."#".$hexData . "\n" if($debug);

  # Adjust display
  $command = $temps{$command} if ($temps{$command});
  if ($year == '2016' and $command < 6) {
    $dgnhi = '1FF';
    $dgnlo = '9C';
    $binCanId = sprintf("%b0%b%b%b", hex($prio), hex($dgnhi), hex($dgnlo), hex($srcAD));
    $hexCanId = sprintf("%08X", oct("0b$binCanId"));
    $hexData =  sprintf("%02X%02X22FFFFFFFF%02X", $indicator[$floor], $levels{$command}[2], $command);
    system('cansend can0 '.$hexCanId."#".$hexData) if (!$debug);
    print 'cansend can0 '.$hexCanId."#".$hexData . "\n" if($debug);
  }
}

# Starting in 2017, the floor heat level can not be set directly, it can only
# be incremented or decremented. To adjust the heat level a
# GENERIC_INDICATOR_COMMAND (1FED9) must be sent to the RSI-9 which handles the
# climate control. 2017 coaches target the 0x92 RSI-9 node group, while 2018
# coaches target the 0x98 RSI-9 node group. 0x66 represents zone 0 (front) and
# 0x67 represents zone 1 (rear).
#
# increment heat level: FF <rsi-9> <zone> 0F 01 00 D2 EA
# decrement heat level: FF <rsi-9> <zone> 0F FF FF D2 EA
#
sub floor_heat_indirect {
  our ($prio, $dgnhi, $dgnlo, $srcAD) = (6, '1FE', 'D9', '9F');
  our $binCanId = sprintf("%b0%b%b%b", hex($prio), hex($dgnhi), hex($dgnlo), hex($srcAD));
  our $hexCanId = sprintf("%08X", oct("0b$binCanId"));

  my %up_down = ( 'up' => '0100', 'down' => 'FFFF' );
  my %rsi9 = ( '2017' => '92', '2018' => '98' );
  my $hexData = sprintf("FF%s%02X0F%sD2EA", $rsi9{$year}, $floor + hex(66), $up_down{$command});

  # The up or down command may be sent several times to achieve the desired heat level.
  my $count = $ARGV[3] // 1;
  $count = 4 if $count > 4;
  $count = 0 if $count < 0;
  for (my $i = 0; $i < $count; $i++) {
    system('cansend can0 '.$hexCanId."#".$hexData) if (!$debug);
    print 'cansend can0 '.$hexCanId."#".$hexData . "\n" if($debug);
  }
}

# Turn floors on or off. This is the same for all coaches.
sub onoff {
  our ($prio, $dgnhi, $dgnlo, $srcAD) = (6, '1FE', 'F9', 99);
  our $binCanId = sprintf("%b0%b%b%b", hex($prio), hex($dgnhi), hex($dgnlo), hex($srcAD));
  our $hexCanId = sprintf("%08X", oct("0b$binCanId"));

  my %on_off = ( 'on' => 'F2', 'off' => 'F0' );
  my $hexData = sprintf("%02X%sFFFFFFFFFF00", $floor, $on_off{$command});

  system('cansend can0 '.$hexCanId."#".$hexData) if (!$debug);
  print 'cansend can0 '.$hexCanId."#".$hexData . "\n" if($debug);
}

# Show usage information.
sub usage {
	print "\nUsage: \n";
	print "\t$0 <floor-heat-method> <floor-id> <command>\n";

	print "\n\t<floor-heat-method> is one of:\n";
	foreach my $key ( keys %methods ) {
		print "\t\t$key\n";
	}

	print "\n\t<floor-id> is one of:\n";
	foreach my $key ( sort {$a <=> $b} keys %floors ) {
		print "\t\t".$key." = ".$floors{$key} . "\n";
	}

  print "\n\t<command> varies based on floor heat method. For direct method it is\n";
  print "\ta 0-5 value (0 being 'off') or a temperature from 32-104F. For updown\n";
  print "\tmethod it is one of 'on', 'off', 'up', or 'down'. Up and down also accept\n";
  print "\tan optional number of times to execute (e.g. 'up 2').\n";

  exit;
}
