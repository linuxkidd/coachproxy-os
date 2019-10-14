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
use warnings;
use Getopt::Long qw(GetOptions);

my $debug;
my @id;
my @reverse;
my $command = 1;
my $duration = 30;

GetOptions(
  'debug' => \$debug,
  'id=i' => \@id,
  'reverse=i' => \@reverse,
  'command=i' => \$command,
  'duration=i' => \$duration,
) or usage();

usage() if (!@id or !@reverse);

our ($prio, $dgnhi, $dgnlo, $srcAD) = (6, '1FE', 'DB', 96);
our $binCanId = sprintf("%b0%b%b%b", hex($prio), hex($dgnhi), hex($dgnlo), hex($srcAD));
our $hexCanId = sprintf("%08X", oct("0b$binCanId"));

my $hexData = '';

# In case multiple IDs were provided, loop through each pair of IDs
for (my $i = 0; $i < scalar(@id); $i++) {
  # Stop the opposing instance
  $hexData = sprintf("%02XFF%02X%02X%02X00FFFF", $reverse[$i], 0, 3, 0);
  system("cansend can0 ${hexCanId}#$hexData") if (!$debug);
  print "cansend can0 ${hexCanId}#$hexData\n" if ($debug);

  # Engage the main instance
  $hexData = sprintf("%02XFF%02X%02X%02X00FFFF", $id[$i], 100*2, $command, $duration);
  system("cansend can0 ${hexCanId}#$hexData") if (!$debug);
  print "cansend can0 ${hexCanId}#$hexData\n" if ($debug);
}

exit;

sub usage {
  print qq{
    Arguments:

    --id <num>            the ID of the device to activate            [required]
    --reverse <num>       the opposing ID of the device to deactivate [required]
    --command <num>       the DC_DIMMER_COMMAND_2 "on" command to use [default = 1]
    --duration <seconds>  the DC_DIMMER_COMMAND_2 duration to use     [default = 30]
    --debug               print cansend command instead of executing

    Multiple --id and --reverse arguments may be provided to actuate multiple devices.
  };
  print "\n";

  exit(1);
}
