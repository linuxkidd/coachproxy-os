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

# Read configuration settings from a sqlite3 database and build a custom
# CoachProxy node-red flows file from it.

use strict;
use Getopt::Long;
use JSON::Parse 'parse_json','json_file_to_perl';
use DBI;

sub logger {
  system("/coachproxy/bin/cplog.sh \"cp_config.pl $_[0]\"");
}

our $debug = 0;
our $rebuild_habridge = 0;
our $reboot = 0;

GetOptions(
  'debug' => \$debug,
  'habridge' => \$rebuild_habridge,
  'reboot' => \$reboot,
);

our $template = "/coachproxy/configurator/flows_coachproxy-template.json";

our $dbh = DBI->connect('DBI:SQLite:/coachproxy/node-red/coachproxy.sqlite', '', '', { RaiseError => 1 }) or die $DBI::errstr;
our $sth;

sub query {
  my ($stmt) = @_;

  $sth = $dbh->prepare($stmt);
  my $rv = $sth->execute() or die $DBI::errstr;
  if($rv < 0) {
     print $DBI::errstr;
  }
}


sub abort {
  print "ERROR: new flows_coachproxy.json file is empty. Aborting." if ($debug);
  system('/usr/local/bin/mqtt-simple -h localhost -p "GLOBAL/SHUTDOWN" -m "Unknown error! Aborting reconfiguration..."');
  die("Error");
}


# Search the flows file and collect the IDs of the various user interface tab
# (ui_tab) nodes
sub tab_ids {
  my %t;
  my $result = `jq '[ .[] | select (.type == "ui_tab") ]' < $template`;
  my $tabs = parse_json($result);
  foreach my $tab (@$tabs) {
    $t{$tab->{'name'}} = $tab->{'id'};
  }
  return %t;
}


sub create_habridge_device {
  my ($group_id, $device_id, $name, $cmd, $on, $off, $dim) = @_;

  my $bridge_id = $group_id * 256 + $device_id;
  my $unique_id = sprintf("00:17:88:5E:%02X:%02X-%02X", $group_id, $device_id, $device_id);

  my $item = "";
  # Assume the panel lights (group 6 id 126) is always the first to be added to the list.
  # Everything else needs a comma in front.
  if ($bridge_id != (6 * 256 + 126)) {
    $item .= ",\n";
  }
  $item .= "{\n";
  $item .= "  \"name\" : \"$name\",\n";
  $item .= "  \"onUrl\" : \"[{\\\"item\\\":\\\"/coachproxy/rv-c/$cmd $on\\\",\\\"type\\\":\\\"cmdDevice\\\"}]\",\n";
  $item .= "  \"offUrl\" : \"[{\\\"item\\\":\\\"/coachproxy/rv-c/$cmd $off\\\",\\\"type\\\":\\\"cmdDevice\\\"}]\",\n";
  if ($dim) {
    $item .= "  \"dimUrl\" : \"[{\\\"item\\\":\\\"/coachproxy/rv-c/$cmd $dim\\\",\\\"type\\\":\\\"cmdDevice\\\"}]\",\n";
  }
  $item .= "  \"id\" : \"$bridge_id\",\n";
  $item .= "  \"uniqueid\" : \"$unique_id\"\n";
  $item .= "}";

  return $item;
}


#
# Main program entry
#

query "SELECT key, value from configs;";

our %configs;
while(my @row = $sth->fetchrow_array()) {
  $configs{$row[0]} = $row[1];
}

my ($year, $model, $floorplan) = ($configs{'year'}, $configs{'model'}, $configs{'floorplan'});
my $features_file = json_file_to_perl('/coachproxy/configurator/features.json');
my $features = $features_file->{$year}{$model}{'Default'} || die("Unknown default features configuration");

print "$year $model $floorplan\n" if ($debug);
logger("rebuilding node-red flows file for $year $model $floorplan");

# Get the name and ID of each user interface tab
my %tabs = tab_ids();

# Space separated list of tags to delete from the flow template
our @tags;

# Beginnings of a jq filter to make other changes to the flow template
my $filter = ".[]";

# String for building habridge device.db
my $devicedb = "[";

# Keep track of how many entries remain in the Save Presets dialog. This is used to
# ensure the remaining elements line up correctly.
my $preset_feature_count = 4;

###############################################################################
#
# Panel lights
#
$devicedb .= create_habridge_device(6, 126, 'Panel Lights', "panel_lights.pl 126", 100, 0, '${intensity.percent}');


###############################################################################
#
# Engine Pre-Heat
#

# Delete if coach does not have Aqua-Hot
if ($configs{'aquahot'} eq 'false') {
  push @tags, '/preheat_out/';
}


###############################################################################
#
# Aqua-Hot
#
my $lpg = "true";

if ($configs{'aquahot'} eq 'true') {
  $lpg = "false";
  push @tags, '/lpg/';              # Delete LPG nodes
  push @tags, '/waterheat-label/';  # Delete water heat label
} else {
  push @tags, '/aquahot-label/';    # Delete aqua-hot label
}

if ($year == 2014) {
  $lpg = 'false';
  push @tags, '/lpg/ /waterheat-label/ /aquahot-label/';
}

if ($model eq 'Wayfarer') {
  push @tags, '/waterheat-label/ /aquahot-label/';
}

query "INSERT OR REPLACE INTO configs (key, value) VALUES('lpg', '$lpg');";

###############################################################################
#
# Thermostats
#
my $tstats = 'true';
my $settings_tstat_first_zone = 2;

if (substr($model, 0, 8) ne "VanLeigh" and ($year < 2018 or $model eq 'Wayfarer')) {
  # No thermostats before 2018
  $tstats = 'false';
  push @tags, qw(/tstat/ /tstat0/ /tstat1/ /tstat2/ /furn0/ /furn1/);
  $preset_feature_count--;
} else {
  if (!grep(/^$model$/, ('Phaeton', 'Allegro_Bus', 'Zephyr'))) {
    $settings_tstat_first_zone = 0; # Lower-end coaches use zones 0/1/2 instead of 2/3/4
  }
  if ($configs{'thirdtstat'} ne 'true') {
    push @tags, '/tstat1/'; # Delete middle thermostat zone if coach only has two zones
  }
  if ($configs{'secondfurnace'} ne 'true') {
    push @tags, '/furn1/';  # Delete rear furnace button if coach only has one furnace
  } else {
    push @tags, '/furn1-spacer/';
  }
  if ($configs{'midheat'} ne 'true') {
    push @tags, '/heatpump1/';         # Delete heat pump button
  } else {
    push @tags, '/heatpump1-spacer/';  # Delete heat pump spacer
  }
  if ($configs{'rearheat'} ne 'true') {
    push @tags, '/heatpump2/';        # Delete heat pump button
  } else {
    push @tags, '/heatpump2-spacer/'; # Delete heat pump spacer
  }
}

query "INSERT OR REPLACE INTO configs (key, value) VALUES('tstats', '$tstats');";
query "INSERT OR REPLACE INTO settings2 (key, value) VALUES('tstat_first_zone', '$settings_tstat_first_zone');";

###############################################################################
#
# External temperature readings
#
my $exttemp = 'true';

if ($year < 2018 or !grep(/^$model$/, ('Phaeton', 'Allegro_Bus', 'Zephyr'))) {
  $exttemp = 'false';
  push @tags, '/exttemp/';
}

query "INSERT OR REPLACE INTO configs (key, value) VALUES('exttemp', '$exttemp');";

###############################################################################
#
# Heated Floors
#
my $settings_floor_heat_method = 'none';
if ($configs{'floorheat'} eq 'true') {
  if ($year < 2017) {
    $settings_floor_heat_method = "direct$year";
    push @tags, '/floorheat-indirect/';
  } else {
    $settings_floor_heat_method = 'updown2017' if ($year == 2017);
    $settings_floor_heat_method = 'updown2018' if ($year >= 2018);
    push @tags, '/floorheat-direct/';
  }
  query "INSERT OR REPLACE INTO settings2 (key, value) VALUES('floor_heat_method', '$settings_floor_heat_method');";
} else {
  # Delete heated floor controls
  push @tags, '/floorheat/';
  $preset_feature_count--;
}


###############################################################################
#
# Chassis Status:
#
my $chassis_entries = 2;

# Ignition Status
if ($features->{'Ignition'} == 0) {
  push @tags, '/ignition/';
  $chassis_entries--;
}

# Park Brake
if ($features->{'ParkBrake'} == 0) {
  push @tags, '/parkbrake/';
  $chassis_entries--;
}

# If there are no entries in the "Chassis" section, delete the label too.
if ($chassis_entries == 0) {
  push @tags, '/chassislabel/';
}


###############################################################################
#
# Generator Status
#
if ($features->{'GeneratorStatus'} == 0) {
  push @tags, '/genstatus/';
}


###############################################################################
#
# Generator Controls
#
my $gencontrol = 'true';
my $settings_generator_version = '1';

if (grep(/^$model$/, ('Allegro_RED', 'Phaeton', 'Allegro_Bus', 'Zephyr'))) {
  $settings_generator_version = '0' if ($year == 2014);
  $settings_generator_version = '1' if ($year == 2015);
  $settings_generator_version = '2' if ($year >= 2016);
  $settings_generator_version = '3' if ($year >= 2018);
  if ($model eq 'Phaeton' && $year < 2018) {
    # Generator controls not included on Phaeton until 2017
    $gencontrol = 'false';
    push @tags, '/gencontrol/';
  }
  if ($model eq 'Allegro_RED') {
    $settings_generator_version = '2';
    if ($year < 2019) {
      # Generator controls not included on RED until 2019
      $gencontrol = 'false';
      push @tags, '/gencontrol/';
    }
  }
  query "INSERT OR REPLACE INTO settings2 (key, value) VALUES('generator_version', '$settings_generator_version');";
} else {
  $gencontrol = 'false';
  push @tags, '/gencontrol/';
}
query "INSERT OR REPLACE INTO configs (key, value) VALUES('gencontrol', '$gencontrol');";

###############################################################################
#
# ATS
#
my $ats = 'true';
if ($year < 2018 or !grep(/^$model$/, ('Phaeton', 'Allegro_Bus', 'Zephyr'))) {
  # Only 2018 Phaeton, Bus, and Zephyr have ATS readings
  $ats = 'false';
  push @tags, '/ats/';
}
query "INSERT OR REPLACE INTO configs (key, value) VALUES('ats', '$ats');";


###############################################################################
#
# Battery voltage
#

my $batt_chassis = 'true';

# In 2018, Spyder changed the battery status IDs on Phaeton and above
if ($year < 2018 or !grep(/^$model$/, ('Phaeton', 'Allegro_Bus', 'Zephyr'))) {
  push @tags, '/battery-advanced/';
} else {
  push @tags, '/battery-basic/';
}

# No chassis batteries in 2015
if ($year == 2015) {
  $batt_chassis = 'false';
  push @tags, '/battery-chassis/';
}

# No chassis batteries on Open Roads before 2018
if ($year < 2018 and grep(/^$model$/, ('Allegro_Open_Road'))) {
  $batt_chassis = 'false';
  push @tags, '/battery-chassis/';
}

# No chassis battery on Wayfarer or Vilano
if (grep(/^$model$/, ('Wayfarer', 'VanLeigh_Vilano', 'VanLeigh_Beacon'))) {
  $batt_chassis = 'false';
  push @tags, '/battery-chassis/';
}

query "INSERT OR REPLACE INTO configs (key, value) VALUES('batt_chassis', '$batt_chassis');";

###############################################################################
#
# Ceiling Fan
#
if ($configs{'ceilfan'} ne "true" or $year == 2014) {
  push @tags, '/ceilfan/';
} elsif ($year >= 2018 and $model eq 'Allegro_Open_Road') {
  # 2018-2019 Open Roads use different ceiling fan IDs.
  $filter .= " | if (.name != null) and (.name | contains(\"/ceilfan_low/\")) then .topic = \"RVC/DC_DIMMER_STATUS_3/33\" else . end";
  $filter .= " | if (.name != null) and (.name | contains(\"/ceilfan_high/\")) then .topic = \"RVC/DC_DIMMER_STATUS_3/34\" else . end";
  $filter .= " | if (.name != null) and (.name | contains(\"/ceilfan_switch/\")) then .topic = \"2\" else . end";
  $devicedb .= create_habridge_device(8, 1, 'Ceiling Fan', "ceiling_fan.pl 2", 2, 0);
} else {
  $devicedb .= create_habridge_device(8, 1, 'Ceiling Fan',  "ceiling_fan.pl 1", 2, 0);
}

###############################################################################
#
# Bedroom Lift TV - only present in 2018 Zephyr 45 PZ
#
my $has_bedroom_tv_lift = 0;
if ($year == 2018 and $floorplan eq '45_PZ') {
  $devicedb .= create_habridge_device(9, 1, 'Bedroom TV Lift',  "lift.pl 2", 'u', 'd');
  $has_bedroom_tv_lift = 1;
} else {
  push @tags, '/bed_tvlift/';
}

###############################################################################
#
# Lift TV
#
if ($configs{'tvlift'} ne "true") {
  push @tags, '/tvlift/';
} else {
  my $tv_voice_name = ($has_bedroom_tv_lift == 1 ? 'Front TV Lift' : 'TV Lift');
  if ($year >= 2019 and $model eq 'Allegro_RED') {
    # 2019 REDs use different TV Lift IDs.
    $filter .= " | if (.name == \"TV Up\") then .topic = \"3\" else . end";
    $filter .= " | if (.name == \"TV Down\") then .topic = \"3\" else . end";
    $devicedb .= create_habridge_device(9, 2, $tv_voice_name,  "lift.pl 3", 'u', 'd');
  } else {
    $devicedb .= create_habridge_device(9, 2, $tv_voice_name,  "lift.pl 0", 'u', 'd');
  }
}

###############################################################################
#
# Bed Lift
#
if ($configs{'powerbed'} ne "true") {
  push @tags, '/bedlift/';
} else {
  $devicedb .= create_habridge_device(9, 3, 'Bed Lift',  "lift.pl 1", 'u', 'd');
}

###############################################################################
#
# Bus Undercoach Light
#
if ($configs{'busundercoach'} ne "true") { push @tags, '/light_85/'; }

###############################################################################
#
# Optionally move shade controls to the Interior tab
#
if ($configs{'shades_interior'} eq "true") {
  $filter .= " | if (.type == \"ui_group\") and (.name != null) and (.name | contains(\"Shades\")) then";
  $filter .= " .order = \"90\" | .tab = \"$tabs{'Interior'}\" else . end";
}

###############################################################################
#
# Update comment node in Admin interface
#
$filter .= " | if (.name != null) and (.name | contains(\"CoachProxy Template\")) then .name = \"$year $model $floorplan\" else . end";

###############################################################################
# If there are an even number of switches remaining in the Save Presets panel,
# things will line up correctly and the spacer is not needed.
if ($preset_feature_count % 2 == 0) {
  push @tags, "/preset-feature-spacer/";
}

###############################################################################
#
# Create a new config from the template
#

my $tmpfile = "/tmp/flows_coachproxy.json"; # Node-RED flows
my $tmpfile2 = "/tmp/device.db";            # Alexa habridge

# Create ha-bridge device.db with non-light devices
open(my $fh, ">", $tmpfile2) or die "Could not open file $tmpfile2 $!";
print $fh $devicedb;
close $fh;

my $taglist = join ' ', @tags;
print "Removing nodes: $taglist\n" if ($debug);
system("cp $template $tmpfile");
system("/coachproxy/configurator/node_remover.pl $tmpfile $taglist");
if (-z "$tmpfile") { abort(); }

print "Updating miscellaneous features: $filter\n" if ($debug);
$filter = "[ $filter ]"; # Return results as an array
system("jq '$filter' < $tmpfile > ${tmpfile}_edit");
system("mv ${tmpfile}_edit $tmpfile");
if (-z "$tmpfile") { abort(); }

print "Updating lights.\n" if ($debug);
system("/coachproxy/configurator/node_changer.pl $tmpfile $tmpfile2 $year $model $floorplan");
if (-z "$tmpfile") { abort(); }

# Create ha-bridge device.db with non-light devices
open($fh, ">>", $tmpfile2) or die "Could not open file $tmpfile2 $!";
print $fh ']';
close $fh;

# Remove old backup files
system('sudo find /coachproxy/node-red/ -name "flows_coachproxy.json.~*" -mtime +30 -delete');
system('sudo find /coachproxy/ha-bridge/ -name "device.db.~*" -mtime +30 -delete');

if ($rebuild_habridge) {
  # Install new ha-bridge config file
  logger("installing new ha-bridge/device.db file");
  system("sudo mv --backup=numbered /tmp/device.db /coachproxy/ha-bridge/");
} else {
  # Install new node-red config files
  logger("installing new flows_coachproxy.json file");
  system("sudo mv --backup=numbered /tmp/flows_coachproxy.json /coachproxy/node-red/");
  system('/usr/local/bin/mqtt-simple -h localhost -p "GLOBAL/SHUTDOWN" -m "Restarting CoachProxy..."');
  sleep(1);
  if ($reboot) {
    logger("rebooting CoachProxyOS device");
    system("sudo /coachproxy/bin/safe_reboot");
  } else {
    system("/coachproxy/bin/version.sh");
    logger("restarting node-red");
    # Note: if this script was called from within nodered, the below statement will kill this script.
    system("sudo systemctl restart nodered");
  }
}
