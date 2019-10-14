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
use Net::MQTT::Simple "localhost";
no strict 'refs';

our $debug=0;

our %deccommands=(0=>'Stop',1=>'Start');
our @versions=('2014','2015','2016+', '2018+');

# [ stop_id, start_id ]
our @load_ids=(
	[18,14],
	[104,103],
	[104,103],
	[84,83]
);

our $prime_time=5;
our $start_time=30;
our $stop_time=30;
our $end_time;

if ( scalar(@ARGV) < 2 ) {
	print "ERR: Insufficient command line data provided.\n";
	usage();
}

if(!exists($versions[$ARGV[0]])) {
	print "ERR: Version not present.  Please see Version list below.\n";
	usage();
}

if(!exists($deccommands{$ARGV[1]})) {
	print "ERR: Command not allowed.  Please see Command list below.\n";
	usage();
}

sub send_message {
	my ($message)=@_;
	publish "GENSTART/MESSAGE" => "$message";
}

our @desired_state=('stopped','running');

our ($prio,$dgnhi,$dgnlo,$srcAD,$ver,$command)=(6,'1FE','DB',99,$ARGV[0],$ARGV[1]);
our $binCanId=sprintf("%b0%b%b%b",hex($prio),hex($dgnhi),hex($dgnlo),hex($srcAD));

our $hexCanId=sprintf("%08X",oct("0b$binCanId"));
our $hexData=sprintf("%02XFFC8%02XFF00FFFF",$load_ids[$ver][0],1);
our ($currstate,$diff)=('',0);
our @status=();


if($ver>1) {
	@status=split(',',`mqtt-simple -h localhost -s CP/GENERATOR_STATUS -1`);
	chomp($status[1]);
	$diff=abs(time-$status[1]);
	if($diff<3) {
		print $status[0] ." -> ". $status[1]." -- $diff\n" if($debug);
	} else {
		send_message("Stale Generator State.  Aborting start attempt.");
		die("Stale MQTT status for Generator.  Aborting start attempt.\n");
	}
	$currstate=$status[0];
	if($currstate eq $desired_state[$command]) {
		send_message("Generator already $currstate");
		print "Generator already $currstate\n";
		$hexData=sprintf("%02XFFC8%02XFF00FFFF",$load_ids[$ver][0],4);
		system('cansend can0 '.$hexCanId."#".$hexData) if(!$debug);
		print 'cansend can0 '.$hexCanId."#".$hexData."\n" if($debug);
		$hexData=sprintf("%02XFFC8%02XFF00FFFF",$load_ids[$ver][1],4);
		system('cansend can0 '.$hexCanId."#".$hexData) if(!$debug);
		print 'cansend can0 '.$hexCanId."#".$hexData."\n" if($debug);
		exit;
	}
}

if($command==0) {
	send_message("Attempting to stop");
	print "Attempting to stop: " if($debug);
	$hexData=sprintf("%02XFFC8%02XFF00FFFF",$load_ids[$ver][1],4);
	system('cansend can0 '.$hexCanId."#".$hexData) if(!$debug);
	print 'cansend can0 '.$hexCanId."#".$hexData."\n" if($debug);

	$hexData=sprintf("%02XFFC8%02XFF00FFFF",$load_ids[$ver][0],1);
	system('cansend can0 '.$hexCanId."#".$hexData) if(!$debug);
	print 'cansend can0 '.$hexCanId."#".$hexData."\n" if($debug);
	if($ver>1) {
		$end_time=time+$stop_time;
		while($currstate ne $desired_state[$command] && (time<$end_time)) {
			@status=split(',',`mqtt-simple -h localhost -s CP/GENERATOR_STATUS -1`);
			chomp($status[1]);
			$diff=abs(time-$status[1]);
			if($diff>3) {
				send_message("Stale Generator State.  Aborting stop attempt.");
				die("Stale MQTT status for Generator.  Aborting stop attempt.\n");
			}
			print $status[0] ." -> ". $status[1]." -- $diff\n" if($debug);
			$currstate=$status[0];
		}
	} else {
		sleep $stop_time;
	}
	$hexData=sprintf("%02XFFC8%02XFF00FFFF",$load_ids[$ver][0],4);
	system('cansend can0 '.$hexCanId."#".$hexData) if(!$debug);
	print 'cansend can0 '.$hexCanId."#".$hexData."\n" if($debug);
	if($ver>1) {
		if($currstate ne $desired_state[$command]) {
			send_message("Generator never reported 'stopped' in $stop_time seconds.");
			die("Generator never reported 'Stopped' in $stop_time seconds.\n");
		}
		send_message("Generator Stopped");
	} else {
		send_message("Done");
	}
} elsif ($command==1) {
	send_message("Priming for $prime_time seconds.");
	print "Priming for $prime_time seconds: " if($debug);
	system('cansend can0 '.$hexCanId."#".$hexData) if(!$debug);
	print 'cansend can0 '.$hexCanId."#".$hexData."\n" if($debug);

	sleep $prime_time;

	$hexData=sprintf("%02XFFC8%02XFF00FFFF",$load_ids[$ver][0],4);
	system('cansend can0 '.$hexCanId."#".$hexData) if(!$debug);
	print 'cansend can0 '.$hexCanId."#".$hexData."\n" if($debug);

	sleep 1;

	$hexData=sprintf("%02XFFC8%02XFF00FFFF",$load_ids[$ver][1],1);
	send_message("Attempting to start for $start_time seconds.");
	print "Attempting to start for $start_time seconds: " if($debug);
	system('cansend can0 '.$hexCanId."#".$hexData) if(!$debug);
	print 'cansend can0 '.$hexCanId."#".$hexData."\n" if($debug);

	if($ver>1) {
		$end_time=time+$start_time;
		while($currstate ne $desired_state[$command] && (time<$end_time)) {
			@status=split(',',`mqtt-simple -h localhost -s CP/GENERATOR_STATUS -1`);
			chomp($status[1]);
			$diff=abs(time-$status[1]);
			if($diff>3) {
				$hexData=sprintf("%02XFFC8%02XFF00FFFF",$load_ids[$ver][1],4);
				system('cansend can0 '.$hexCanId."#".$hexData) if(!$debug);
				print 'cansend can0 '.$hexCanId."#".$hexData."\n" if($debug);
				send_message("Stale Generator State.  Aborting start attempt.");
				die("Stale MQTT status for Generator.  Aborting start attempt.\n");
			}
			print $status[0] ." -> ". $status[1]." -- $diff\n" if($debug);
			$currstate=$status[0];
		}
	} else {
	        sleep $start_time;
	}
	$hexData=sprintf("%02XFFC8%02XFF00FFFF",$load_ids[$ver][1],4);
	system('cansend can0 '.$hexCanId."#".$hexData) if(!$debug);
	print 'cansend can0 '.$hexCanId."#".$hexData."\n" if($debug);
	if($ver>1) {
		if($currstate ne $desired_state[$command]) {
			send_message("Generator Start Failed");
			exit 1;
		}
		send_message("Generator Started");
	} else {
		send_message("Done");
	}
}

sub usage {
	our $prime_time;
	our $start_time;
	our %deccommands;
	our @versions;
	print "Usage: \n";
	print "\t$0 <version> <command>\n";
	print "\n\t<version> is required and one of the following based on model year:\n";
	for(my $i=0;my $ver=$versions[$i];$i++) {
		print "\t\t".$i." = ".$ver . "\n";
	}
	print "\n\t<command> is required and one of:\n";
	foreach my $key ( sort {$a <=> $b} keys %deccommands ) {
		print "\t\t".$key." = ".$deccommands{$key} . "\n";
	}
	print "\n";
	print "NOTE: Starting the Generator can take some time.  For 'Start' operation, this\n";
	print "	script will perform the following actions:\n";
	print "\n";
	print "	* Prime for $prime_time seconds\n";
	print "	* Attempt to start for $start_time seconds\n";
	print "	* If the generator has not entered 'Running' state after 30 seconds, the script\n";
	print "		will exit with status 1.\n";
	print "\n";
	exit(1);
}

