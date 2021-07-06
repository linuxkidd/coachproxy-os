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

our %ls=(
  0 => "TV Lift",
  1 => "Bed Lift",
  2 => "Rear TV Lift",
  3 => "2019 RED TV Lift",
  4 => "Beacon Vilano TV Lift"
);

our %mappings=(
  0=>{ 'u'=>[43,44], 'd'=>[44,43] },
  1=>{ 'u'=>[41,42], 'd'=>[42,41] },
  2=>{ 'u'=>[45,46], 'd'=>[46,45] },
  3=>{ 'u'=>[17,21], 'd'=>[21,17] },
  4=>{ 'u'=>[34,35], 'd'=>[35,34] }
);

our %ds=('u'=>1, 'd'=>1);

if ( scalar(@ARGV) < 2 ) {
  print "ERR: Insufficient command line data provided.\n";
  usage();
}

if(!exists($ls{$ARGV[0]})) {
  print "ERR: Lift Location does not exist.  Please see Location list below.\n";
  usage();
}

if(!exists($ds{$ARGV[1]})) {
  print "ERR: Direction not allowed.  Please see Direction list below.\n";
  usage();
}


my ($loc,$dir)=($ARGV[0],$ARGV[1]);

shade($loc,$dir);

sub shade {
  my ($loc,$dir) = @_;
  our %ds;
  our %mappings;
  my ($prio,$dgnhi,$dgnlo,$srcAD)=(6,'1FE','DF',96);

  if (ref($mappings{$loc}) eq 'HASH') {
    $dgnlo='DB';
    my $binCanId=sprintf("%b0%b%b%b",hex($prio),hex($dgnhi),hex($dgnlo),hex($srcAD));
    my $hexCanId=sprintf("%08X",oct("0b$binCanId"));

    # Stop the 'Anti' Location
    my $hexData=sprintf("%02XFFC8%02X%02X00FFFF",$mappings{$loc}{$dir}[1],3,0);
    system('cansend can0 '.$hexCanId."#".$hexData) if(!$debug);
    print 'cansend can0 '.$hexCanId."#".$hexData."\n" if($debug);

    # Engage the Location
    $hexData=sprintf("%02XFFC8%02X%02X00FFFF",$mappings{$loc}{$dir}[0],5,30);
    system('cansend can0 '.$hexCanId."#".$hexData) if(!$debug);
    print 'cansend can0 '.$hexCanId."#".$hexData."\n" if($debug);
  } else {
    my $binCanId=sprintf("%b0%b%b%b",hex($prio),hex($dgnhi),hex($dgnlo),hex($srcAD));
    my $hexCanId=sprintf("%08X",oct("0b$binCanId"));
    my $hexData=sprintf("%02XFFC8%02X%02X00FFFF",$mappings{$loc},$ds{$dir},30);

    system('cansend can0 '.$hexCanId."#".$hexData) if(!$debug);
    print 'cansend can0 '.$hexCanId."#".$hexData."\n" if($debug);
  }
}

sub usage {
  print "Usage: \n";
  print "\t$0 <location> <direction>\n";
  print "\n\t<location> is required and one of:\n";
  foreach my $key ( sort {$a <=> $b} keys %ls ) {
    print "\t\t".$key." = ".$ls{$key} . "\n";
  }
  print "\n\t<direction> is required and one of:\n";
  print "\t\td = Toggle Lift Down\n";
  print "\t\tu = Toggle Lift Up\n";
  print "\n";
  exit(1);
}
