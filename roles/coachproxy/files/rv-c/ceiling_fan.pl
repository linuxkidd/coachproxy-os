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

our $debug = 0;

our %loads = (
  1 => "Bedroom",
  2 => "Bedroom (2018+ Open Road)",
);

our %deccommands = (
  0 => 'Off', 1 => 'Low', 2 => 'High',
);

if ( scalar(@ARGV) < 2 ) {
  print "ERR: Insufficient command line data provided.\n";
  usage();
}

if (!exists($loads{$ARGV[0]})) {
  print "ERR: Load does not exist.  Please see load list below.\n";
  usage();
}

if (!exists($deccommands{$ARGV[1]})) {
  print "ERR: Command not allowed.  Please see command list below.\n";
  usage();
}


our ($prio,$dgnhi,$dgnlo,$srcAD,$instance,$command) = (6,'1FE','DB',96,$ARGV[0],$ARGV[1]);
our ($hexData,$binCanId,$hexCanId) = (0,0,0);

our %specials = (
  1 => { 0 => [ 35, 36 ], 1=> [ 35, 36 ], 2 => [ 36, 35 ] },
  2 => { 0 => [ 33, 34 ], 1=> [ 33, 34 ], 2 => [ 34, 33 ] },
);

if (exists($specials{$instance})) {
  $binCanId = sprintf("%b0%b%b%b",hex($prio),hex($dgnhi),hex($dgnlo),hex($srcAD));
  $hexCanId = sprintf("%08X",oct("0b$binCanId"));

  if ($command > 0) {
    $hexData = sprintf("%02XFFC8%02X%02X00FFFF",$specials{$instance}{$command}[1],3,0);
    system('cansend can0 '.$hexCanId."#".$hexData) if (!$debug);
    print 'cansend can0 '.$hexCanId."#".$hexData . "\n" if($debug);

    $hexData = sprintf("%02XFFC8%02X%02X00FFFF",$specials{$instance}{$command}[0],5,255);
    system('cansend can0 '.$hexCanId."#".$hexData) if (!$debug);
    print 'cansend can0 '.$hexCanId."#".$hexData . "\n" if($debug);
  } else {
    $hexData = sprintf("%02XFFC8%02X%02X00FFFF",$specials{$instance}{$command}[0],3,0);
    system('cansend can0 '.$hexCanId."#".$hexData) if (!$debug);
    print 'cansend can0 '.$hexCanId."#".$hexData . "\n" if($debug);

    $hexData = sprintf("%02XFFC8%02X%02X00FFFF",$specials{$instance}{$command}[1],3,0);
    system('cansend can0 '.$hexCanId."#".$hexData) if (!$debug);
    print 'cansend can0 '.$hexCanId."#".$hexData . "\n" if($debug);
  }
}

sub usage {
  print "Usage: \n";
  print "\t$0 <fan-id> <command>\n";
  print "\n\t<fan-id> is one of:\n";
  foreach my $key ( sort {$a <=> $b} keys %loads ) {
    print "\t\t".$key." = ".$loads{$key} . "\n";
  }
  print "\n\t<command> is one of:\n";
  foreach my $key ( sort {$a <=> $b} keys %deccommands ) {
    print "\t\t".$key." = ".$deccommands{$key} . "\n";
  }
  print "\n";
  exit(1);
}
