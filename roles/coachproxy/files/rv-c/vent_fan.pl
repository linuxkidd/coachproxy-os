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

our @versions=('2014-hi','2014-lo','2018-hi', '2018-lo');

our %loads=(
  1 => "Galley",2 => "Mid Bath",3 => "Rear Bath",
);

our %deccommands=(
  2=>'On',3=>'Off',69=>'Up',133=>'Down'
);

if ( scalar(@ARGV) < 3 ) {
  print "ERR: Insufficient command line data provided.\n";
  usage();
}

if(!exists($versions[$ARGV[0]])) {
  print "ERR: Version not present.  Please see Version list below.\n";
  usage();
}

if(!exists($loads{$ARGV[1]})) {
  print "ERR: Load does not exist.  Please see load list below.\n";
  usage();
}

if(!exists($deccommands{$ARGV[2]})) {
  print "ERR: Command not allowed.  Please see command list below.\n";
  usage();
}

our ($prio,$dgnhi,$dgnlo,$srcAD,$ver,$instance,$command)=(6,'1FE','DB',96,$ARGV[0],$ARGV[1],$ARGV[2]);

our %specials = ();
our @indicator = ();

if ($ver == 1) {
  # Low Line
  %specials=(
    1=>{2 => 27, 3 => 27, 69 => [ 25, 26], 133=>[ 26, 25]},
    2=>{2 => 30, 3 => 30, 69 => [ 28, 29], 133=>[ 29, 28]},
    3=>{2 => 32, 3 => 32, 69 => [ 33, 34], 133=>[ 34, 33]},
  );
  @indicator = ( 0, 8, 44, 114 );
} elsif ($ver == 3) {
  # Low Line 2018+
  %specials=(
    1=>{2 => 23, 3 => 23, 69 => [ 21, 22], 133=>[ 22, 21]},
    2=>{2 => 19, 3 => 19, 69 => [ 17, 18], 133=>[ 18, 17]},
    3=>{2 => 15, 3 => 15, 69 => [ 13, 14], 133=>[ 14, 13]},
  );
} else {
  # High Line all years
  %specials=(
    1=>{2 => 25, 3 => 25, 69 => [ 26, 27], 133=>[ 27, 26]},
    2=>{2 => 29, 3 => 29, 69 => [ 30, 31], 133=>[ 31, 30]},
    3=>{2 => 32, 3 => 32, 69 => [ 33, 34], 133=>[ 34, 33]},
  );
  @indicator = ( 0, 39, 54, 114 );
}

our %status  = ( 69=>3,  133=>2 );
our $binCanId=sprintf("%b0%b%b%b",hex($prio),hex($dgnhi),hex($dgnlo),hex($srcAD));
our $hexCanId=sprintf("%08X",oct("0b$binCanId"));
our $hexData;

if (exists($specials{$instance})) {

  if($command > 3) {
    # Stop the 'Anti' instance
    $hexData=sprintf("%02XFF00%02X%02X00FFFF",$specials{$instance}{$command}[1],3,0);
    system('cansend can0 '.$hexCanId."#".$hexData) if (!$debug);
    print 'cansend can0 '.$hexCanId."#".$hexData . "\n" if($debug);

    # Engage the instance
    $hexData=sprintf("%02XFFC8%02X%02X00FFFF",$specials{$instance}{$command}[0],1,20);
    system('cansend can0 '.$hexCanId."#".$hexData) if (!$debug);
    print 'cansend can0 '.$hexCanId."#".$hexData . "\n" if($debug);

    # Set the indicator on pre-2018 coaches
    if ($ver < 2) {
      $dgnlo='D9';
      $binCanId=sprintf("%b0%b%b%b",hex($prio),hex($dgnhi),hex($dgnlo),hex($srcAD));
      $hexCanId=sprintf("%08X",oct("0b$binCanId"));
      $hexData=sprintf("%02Xff00ffffff%02Xff",$indicator[$instance],$status{$command});
      system('cansend can0 '.$hexCanId."#".$hexData) if (!$debug);
      print 'cansend can0 '.$hexCanId."#".$hexData . "\n" if($debug);
    }

  } else {
    $hexData=sprintf("%02XFFC8%02X%02X00FFFF",$specials{$instance}{$command},$command,255);
    system('cansend can0 '.$hexCanId."#".$hexData) if (!$debug);
    print 'cansend can0 '.$hexCanId."#".$hexData . "\n" if($debug);
  }
}

sub usage {
  print "Usage: \n";

  print "\t$0 <version> <fan-id> <command>\n";
  print "\n\t<version> is required and one of the following based on model year:\n";
  for(my $i=0;my $ver=$versions[$i];$i++) {
    print "\t\t".$i." = ".$ver . "\n";
  }

  print "\n\t<fan-id> is required and one of:\n";
  foreach my $key ( sort {$a <=> $b} keys %loads ) {
    print "\t\t".$key." = ".$loads{$key} . "\n";
  }

  print "\n\t<command> is required and one of:\n";
  foreach my $key ( sort {$a <=> $b} keys %deccommands ) {
    print "\t\t".$key." = ".$deccommands{$key} . "\n";
  }

  print "\n";
  exit(1);
}
