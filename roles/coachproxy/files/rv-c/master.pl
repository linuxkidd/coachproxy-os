#!/usr/bin/perl
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

$debug = 0;

if ( scalar(@ARGV) < 2 ) {
	print "ERR: Insufficient command line data provided.\n";
	usage();
}

my $command = shift;

$prio = 6;
$dgnhi = '1FE';
$dgnlo = 'DB';
$srcAD = '99';

$binCanId = sprintf("%b0%b%b%b", hex($prio), hex($dgnhi), hex($dgnlo), hex($srcAD));

$duration = 0;
if ($command == 0) {
	$cmd = 6;        # Turn off and remember previous value
	$level = 0;      # 0%
} elsif ($command == 1) {
	$cmd = 0;        # Set to level
	$level = 251;    # Master memory value
} elsif ($command == 2) {
	$cmd = 1;        # Set to level
	$level = 200;    # 100%
  $duration = 255; # Continuous
} else {
  die('Unknown command');
}

foreach my $id (@ARGV) {
	$hexData = sprintf("%02XFF%02X%02X%02X00FFFF", $id, $level, $cmd, $duration);
	$hexCanId = sprintf("%08X",oct("0b$binCanId"));

  system('cansend can0 '.$hexCanId."#".$hexData);
	print 'cansend can0 '.$hexCanId."#".$hexData."\n" if ($debug);
}

sub usage {
	print "Usage: \n";
	print "\t$0 <command> <id> ...\n";
	print "\n\t<command> is required and one of:\n";
	print "\t\t0 = Off\n";
	print "\t\t1 = Restore On\n";
	print "\t\t2 = All On\n";
	print "\n";
	print "\n";
	exit(1);
}
