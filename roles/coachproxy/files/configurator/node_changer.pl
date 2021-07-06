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

# Updates dimmer switch and brightness nodes with new values in flows file.
# Adds light controls to Alexa ha-bridge device database.
#
# Search for /light_$id/
#   Update .label
#   Update .group
#   Update .order (*2)
# Search for /brightness_$id/
#   Update .group
#   Update order (*2 +1)
#
# TODO: update .onvalue if needed for Open Road

use strict;
use JSON::Parse 'json_file_to_perl';
use Data::Dumper;

if ( scalar(@ARGV) < 4 ) {
  print "Usage: $0 filename year model floorplan\n";
  exit;
}

our $filename = shift;
our $filename2 = shift;

# Return unique entries from an array
sub uniq {
  my %seen;
  return grep { !$seen{$_}++ } @_;
}

# Search the flows file and collect the IDs of the various user interface group
# (ui_group) nodes
#
# TO DO: Combine this into one jq statement that returns the $group and
# id ("$group," + .id) and parse the results.
sub group_ids {
  my %g;
  foreach my $group (@_) {
    my $id = `jq '.[] | select ((.type == "ui_group") and (.name == "$group")) | .id' < $filename`;
    $g{$group} = $id;
    $g{$group} =~ s/\s+$//;  # Remove newline at end of string
  }
  return %g;
}

sub add_light_to_habridge {
  my ($dimmable, $light_id, $name, $group) = @_;
  my %alexa_group_names = (
    DS => 'Driver', PS => 'Passenger', M => '', MB => 'Mid Bath',
    BR => 'Bedroom', RB => 'Rear Bath', C => 'Closet', E => '',
    LR => 'Living Room', G => 'Galley', H => 'Hall', FB => 'Front Bath'
  );

  my $group_id = 0;
  my $device_id = $light_id;

  my $bridge_id = $group_id * 256 + $device_id;
  my $unique_id = sprintf("00:17:88:5E:%02X:%02X-%02X", $group_id, $device_id, $device_id);

  # Create the full name by combining the location (e.g. Driver) and name (e.g. Ceiling).
  my $fullname = "$alexa_group_names{$group} $name Light";

  # A few special case lights should be renamed, e.g. "Driver Task" isnt' a great name.
  if ($name eq "Task") { $fullname = 'Task Light'; }
  if ($name eq "Courtesy" && $group ne "BR") { $fullname = 'Front Courtesy Light'; }
  if ($name eq "Sconce" && $group ne "BR") { $fullname = 'Front Sconce Light'; }
  if ($name eq "Accent" && $group eq "M") { $fullname = 'Front Accent Light'; }
  if ($name eq "Ceiling" && $group eq "M") { $fullname = 'Main Ceiling Light'; }

  my $item = ",\n";
  $item .= "{\n";
  $item .= "  \"name\" : \"$fullname\",\n";
  $item .= "  \"onUrl\" : \"[{\\\"item\\\":\\\"/coachproxy/rv-c/dc_dimmer.pl $light_id 2\\\",\\\"type\\\":\\\"cmdDevice\\\"}]\",\n";
  $item .= "  \"offUrl\" : \"[{\\\"item\\\":\\\"/coachproxy/rv-c/dc_dimmer.pl $light_id 3\\\",\\\"type\\\":\\\"cmdDevice\\\"}]\",\n";
  if ($dimmable) {
    $item .= "  \"dimUrl\" : \"[{\\\"item\\\":\\\"/coachproxy/rv-c/dc_dimmer.pl $light_id 0 \$\{intensity.percent\}\\\",\\\"type\\\":\\\"cmdDevice\\\"}]\",\n";
  }
  $item .= "  \"id\" : \"$bridge_id\",\n";
  $item .= "  \"uniqueid\" : \"$unique_id\"\n";
  $item .= "}";

  open(my $fh, ">>", $filename2) or die "Could not open file $filename2 $!";
  print $fh $item;
  close $fh;
}

sub add_light_master_to_habridge {
  my $group_id = 0;
  my $device_id = 250;

  my $bridge_id = $group_id * 256 + $device_id;
  my $unique_id = sprintf("00:17:88:5E:%02X:%02X-%02X", $group_id, $device_id, $device_id);

  my $item = ",\n";
  $item .= "{\n";
  $item .= "  \"name\" : \"All Lights\",\n";
  $item .= "  \"onUrl\" : \"[{\\\"item\\\":\\\"/coachproxy/rv-c/master.pl 2 $_[0]\\\",\\\"type\\\":\\\"cmdDevice\\\"}]\",\n";
  $item .= "  \"offUrl\" : \"[{\\\"item\\\":\\\"/coachproxy/rv-c/master.pl 0 $_[0]\\\",\\\"type\\\":\\\"cmdDevice\\\"}]\",\n";
  $item .= "  \"id\" : \"$bridge_id\",\n";
  $item .= "  \"uniqueid\" : \"$unique_id\"\n";
  $item .= "}";

  open(my $fh, ">>", $filename2) or die "Could not open file $filename2 $!";
  print $fh $item;
  close $fh;
}

# Generic ha-bridge device adder. This should eventually replace the light-specific ones above.
sub create_habridge_device {
  my ($group_id, $device_id, $name, $cmd, $on, $off, $dim) = @_;

  my $bridge_id = $group_id * 256 + $device_id;
  my $unique_id = sprintf("00:17:88:5E:%02X:%02X-%02X", $group_id, $device_id, $device_id);

  my $item = ",\n";
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

  open(my $fh, ">>", $filename2) or die "Could not open file $filename2 $!";
  print $fh $item;
  close $fh;
}


#############################################################
my ($year, $model, $floorplan) = @ARGV;
my %group_names = (
  DS => 'Driver Side', PS => 'Passenger Side', M => 'Main', MB => 'Mid Bath',
  BR => 'Bedroom', RB => 'Rear Bath', C => 'Closet', E => 'Exterior Lights',
  FB => 'Front Bath', LR => 'Living Room', G => 'Galley', H => 'Hall', AW => 'Awnings',
  GS => 'General Shades', CS => 'Cockpit Shades', MS => 'Main Shades', BS => 'Bedroom Shades'
);
my %groups = group_ids(values %group_names);

my $json = json_file_to_perl('/coachproxy/configurator/features.json');
my @tags;

# Find the default lights for this year and model, or abort if none found.
my $lights_default = $json->{$year}{$model}{'Default'}{'Lights'} || die("Unknown default light configuration");

# Find optional overrides for this floorplan.
my $lights_floorplan = $json->{$year}{$model}{$floorplan}{'Lights'};

# Search the flows file for lights with these IDs.
my @template_lights = (1..96);

# Light IDs above this never have brightness sliders.
my $highest_dimmable_id = $json->{$year}{$model}{'Default'}{'MaxDimmableLight'};
if (!defined($highest_dimmable_id)) {
  $highest_dimmable_id = 0;
}

# Keep track of how many non-dimmable switches are in the bedroom. If
# it ends up being an even number, the spacer before the ceiling fan
# must be removed.
my $bedroom_count = 0;

my @master_lights;
my @all_lights;

# Initial jq filter.
my $filter = '.[]';

##########################################################
#
# Update lights
#
##########################################################

foreach my $light (@template_lights) {
  my $defaults = $lights_default->{$light};
  my $overrides = $lights_floorplan->{$light};

  if ($defaults) {
    # Store the default values for this light
    my ($name, $group, $order) = ($defaults->{'name'}, $defaults->{'location'}, $defaults->{'order'});

    if (defined($overrides)) {
      # Use floorplan-specific overrides for this light

      if ($overrides eq '') {
        # Empty data provided. Delete this light.
        push @tags, "/light_$light/";
        push @tags, "/brightness_$light/";
        $name = '';
      } else {
        # Use the override values when present.
        $name = $overrides->{'name'} || $name;
        $group = $overrides->{'location'} || $group;
        $order = $overrides->{'order'} || $order;
      }
    }
    $order *= 2;

    if ($name ne '') {
      my $dimmable = ($light <= $highest_dimmable_id);

      # Set the name, location, and order of the switch
      $filter .= " | if (.name != null) and (.name | contains(\"/light_$light/\")) then";
      $filter .= " .label = \"$name\" | .order = $order | .group = $groups{$group_names{$group}} else . end";

      if ($dimmable) {
        # Also set the order of the brightness slider
        $order++;
        $filter .= " | if (.name != null) and (.name | contains(\"/brightness_$light/\")) then";
        $filter .= " .order = $order | .group = $groups{$group_names{$group}} else . end";
      } else {
        # Delete dimmer slider
        push @tags, "/brightness_$light/";

        if ($group eq 'BR') {
          # Non dimmable bedroom light. Increment counter to adjust spacing.
          $bedroom_count++;
        }
      }

      push @all_lights, $light;
      if ($group ne 'E') {
        # Interior lights get added to the master on/off control list
        push @master_lights, $light;
      }

      add_light_to_habridge($dimmable, $light, $name, $group);
    }
  } else {
    # No default values found for this light. Delete it.
    push @tags, "/light_$light/";
    push @tags, "/brightness_$light/";
  }
}

# Move the ceiling fan and lifts to the bottom of the Bedroom group.
$filter .= " | if (.name != null) and (.name | contains(\"/ceilfan_spacer/\")) then .order = 90 else . end";
$filter .= " | if (.name != null) and (.name | contains(\"/ceilfan_label/\")) then .order = 91 else . end";
$filter .= " | if (.name != null) and (.name | contains(\"/ceilfan_switch/\")) then .order = 92 else . end";

$filter .= " | if (.name != null) and (.name | contains(\"/bed_tvlift_label/\")) then .order = 93 else . end";
$filter .= " | if (.name != null) and (.name | contains(\"/bed_tvlift_up/\")) then .order = 94 else . end";
$filter .= " | if (.name != null) and (.name | contains(\"/bed_tvlift_down/\")) then .order = 95 else . end";

$filter .= " | if (.name != null) and (.name | contains(\"/bedlift_label/\")) then .order = 96 else . end";
$filter .= " | if (.name != null) and (.name | contains(\"/bedlift_up/\")) then .order = 97 else . end";
$filter .= " | if (.name != null) and (.name | contains(\"/bedlift_down/\")) then .order = 98 else . end";

# If there are an even number of non-dimmable bedroom lights, then things will
# line up correctly and the spacer is not needed.
if ($bedroom_count % 2 == 0) {
  push @tags, "/ceilfan_spacer/";
}

# Update master on/off id list
my $ids = join ' ', @master_lights;
$filter .= " | if (.command != null) and (.command | contains(\"master.pl\")) then .append = \"$ids\" else . end";
add_light_master_to_habridge($ids);

# Update global context initializer with list of lights
$ids = join ',', @all_lights;
$filter .= " | if (.name != null) and (.name | contains(\"Light List\")) then .rules[0].to = \"[$ids]\" else . end";


##########################################################
#
# Update shades
#
##########################################################

my $max_template_shade = 15;
my $current_template_shade = 0;

# Find the default shades for this year and model, or skip the shades section if none found.
my $shades_default = $json->{$year}{$model}{'Default'}{'Shades'};
if ($shades_default) {
  # Find optional overrides for this floorplan.
  my $shades_floorplan = $json->{$year}{$model}{$floorplan}{'Shades'};

  # Loop through every shade ID found in the default or floorplan list
  foreach my $shade (uniq(keys %{$shades_default}, keys %{$shades_floorplan})) {
    # Store the default values for this shade
    my $defaults = $shades_default->{$shade};
    my ($name, $group, $order, $single, $voice_id) = ($defaults->{'name'}, $defaults->{'location'}, $defaults->{'order'}, $defaults->{'single'}, $defaults->{'voiceid'});
    my $voicename = $defaults->{'voicename'} // $name;

    my $overrides = $shades_floorplan->{$shade};
    if (defined($overrides)) {
      # Use floorplan-specific overrides for this shade
      if ($overrides eq '') {
        next;    # Empty data provided. Skip this shade.
      } else {
        # Use the override values when present.
        $name = $overrides->{'name'} || $name;
        $group = $overrides->{'location'} || $group;
        $order = $overrides->{'order'} || $order;
        $single = $overrides->{'single'} || $single;
        $voicename = $overrides->{'voicename'} || $voicename;
      }
    }

    # Set the name, location, and order of the shade
    my ($icon_sun, $icon_moon) = ('', '');
    if ($order == 1) {
      $icon_sun  = "<div style=\\\"float:left;\\\"><i class=\\\"fa fa-fw fa-sun-o\\\" style=\\\"margin-left:44px;\\\"></i></div>\n";
      $icon_moon = "<div style=\\\"float:right;\\\"><i class=\\\"fa fa-fw fa-moon-o\\\" style=\\\"margin-right:44px;\\\"></i></div>\n";
    }
    my $label = "<div style=\\\"height: 14px;\\\">&nbsp;</div>\n<div style=\\\"width: 100%; height: 18px; font-size: 16px; text-align: center\\\">\n$icon_sun<span>$name</span>\n$icon_moon</div>\n";

    $order *= 5;   # Each shade will have 5 elements in the UI.
    $filter .= " | if (.name != null) and (.name | contains(\"/shade_${current_template_shade}_label/\")) then";
    $filter .= " .name = \"$name /shade_${current_template_shade}_label/\" | .format = \"$label\" | .order = $order | .group = $groups{$group_names{$group}} else . end";

    # Fix day shades
    $filter .= " | if (.name != null) and (.name | contains(\"/shade_${current_template_shade}_day_up/\")) then";
    $filter .= " .payload = \"$year day up $shade\" | .order = " . ($order + 1) . " | .group = $groups{$group_names{$group}} else . end";
    $filter .= " | if (.name != null) and (.name | contains(\"/shade_${current_template_shade}_day_down/\")) then";
    $filter .= " .payload = \"$year day down $shade\" | .order = " . ($order + 3). " | .group = $groups{$group_names{$group}} else . end";

    # Fix night shades
    $filter .= " | if (.name != null) and (.name | contains(\"/shade_${current_template_shade}_night_up/\")) then";
    $filter .= " .payload = \"$year night up $shade\" | .order = " . ($order + 2) . " | .group = $groups{$group_names{$group}} else . end";
    $filter .= " | if (.name != null) and (.name | contains(\"/shade_${current_template_shade}_night_down/\")) then";
    $filter .= " .payload = \"$year night down $shade\" | .order = " . ($order + 4) . " | .group = $groups{$group_names{$group}} else . end";

    # Hide individual shades when appropriate
    if ($single) {
      if ($single eq 'night') {
        # Hide day shade
        $filter .= " | if (.name != null) and (.name | contains(\"/shade_${current_template_shade}_day\")) then";
      } else {
        # Hide night shade
        $filter .= " | if (.name != null) and (.name | contains(\"/shade_${current_template_shade}_night\")) then";
      }
      $filter .= " .payload = \"0\" | .icon = \"\" | .bgcolor = \"#fff\" else . end";
    }

    # Add shades to HA Bridge for voice control.
    if ($single) {
      create_habridge_device(1, $shade, "$voicename Shade",       "window_shade.pl $year $single", "down $shade", "up $shade");
    } else {
      my $plural = ($shade =~ /\s/ ? 's' : '');  # More than one shade ID
      $voice_id = $shade if (!$voice_id);
      create_habridge_device(1, $voice_id, "$voicename Day Shade$plural",   "window_shade.pl $year day",   "down $shade", "up $shade");
      create_habridge_device(2, $voice_id, "$voicename Night Shade$plural", "window_shade.pl $year night", "down $shade", "up $shade");
      create_habridge_device(3, $voice_id, "$voicename Shades",             "window_shade.pl $year both",  "down $shade", "up $shade");
    }

    $current_template_shade++;
  }
}

# Delete unused shades from template
my @unused_shades = ($current_template_shade..$max_template_shade);
foreach my $unused_shade (@unused_shades) {
  push @tags, "/shade_$unused_shade";
}


##########################################################
#
# Update awnings
#
##########################################################

my $max_template_awning = 2;
my $current_template_awning = 0;

# Find the awnings for this year and model, or skip the awnings section if none found.
my $awnings_default = $json->{$year}{$model}{'Default'}{'Awnings'};

# Find optional overrides for this floorplan.
my $awnings_floorplan = $json->{$year}{$model}{$floorplan}{'Awnings'};

if ($awnings_default) {
  foreach my $awning (keys %{$awnings_default}) {
    # Store the default values for this awning
    my $defaults = $awnings_default->{$awning};
    my ($name, $type, $order) = ($defaults->{'name'}, $defaults->{'type'}, $defaults->{'order'});
    my $duration = $defaults->{'duration'} // 30;
    my $duration_extend = $defaults->{'duration_extend'} || $duration;
    my $duration_retract = $defaults->{'duration_retract'} || $duration;
    my $overrides = $awnings_floorplan->{$awning};

    if (defined($overrides)) {
      # Use floorplan-specific overrides for this awning

      if ($overrides eq '') {
        # Empty data provided. Delete this awning.
        push @tags, "/awning_$awning/";
        $name = '';
      } else {
        # Use the override values when present.
        $name = $overrides->{'name'} || $name;
        $type = $overrides->{'type'} || $type;
        $order = $overrides->{'order'} || $order;
        $duration = $overrides->{'duration'} || $duration;
        $duration_extend = $overrides->{'duration_out'} || $duration_extend;
        $duration_retract = $overrides->{'duration_retract'} || $duration_retract;
      }
    }
    $order *= 3;   # Each awning will have 3 elements in the UI.

    # Set the name, location, and order of the awning
    my $label = "<div style=\\\"height: 16px;\\\">&nbsp;</div>\n<div style=\\\"width: 100%; height: 8px; border-bottom: 1px solid black; text-align: center\\\">\\n  <span style=\\\"font-size: 16px; background-color: #FEFEFE; padding: 0 10px; margin-left: 10px;\\\">\\n    $name\\n  </span>\\n</div>\\n",
    $filter .= " | if (.name != null) and (.name | contains(\"/awning_${current_template_awning}_label/\")) then";
    $filter .= " .name = \"$name /awning_${current_template_awning}_label/\" | .format = \"$label\" | .order = $order else . end";

    # Set awning info
    $awning =~ s/\D+//g;   # Remove non-numeric characters.
    $filter .= " | if (.name != null) and (.name | contains(\"/awning_${current_template_awning}_retract/\")) then";
    $filter .= " .payload = \"$year $type up $awning --duration=$duration\" | .order = " . ($order + 1) . " else . end";
    $filter .= " | if (.name != null) and (.name | contains(\"/awning_${current_template_awning}_extend/\")) then";
    $filter .= " .payload = \"$year $type down $awning --duration=$duration\" | .order = " . ($order + 2). " else . end";

    $current_template_awning++;

    # Allow user to close awning with voice commands, but not open it.
    create_habridge_device(4, $awning, "$name Awning", "window_shade.pl --duration=$duration $year $type", "", "up $awning");
  }
}

# Delete unused awnings from template
my @unused_awnings = ($current_template_awning..$max_template_awning);
foreach my $unused_awning (@unused_awnings) {
  push @tags, "/awning_$unused_awning";
}

# If there are no awnings at all, delete the awning messages
if ($current_template_awning == 0) {
  push @tags, qw(/awning-message/ /awning-enabler/);
}

##########################################################
#
# Update vents/fans
#
##########################################################

# Find the vents for this year, model, and floor plan
my $vents = $json->{$year}{$model}{'Default'}{'Vents'};
my %vent_habridge_names = ('galley' => 'Kitchen', 'mid' => 'Mid Bath', 'rear' => 'Rear Bath');
if ($vents) {
  foreach my $vent ('galley', 'mid', 'rear') {
    my $vent_ids = $vents->{$vent};
    if (!defined($vent_ids)) {
      # No data. Delete this vent/fan.
      push @tags, "/ventfan-$vent";
    } else {
      my ($fan, $lidup, $liddn, $indicator) = ($vent_ids->{'fan'}, $vent_ids->{'lidup'}, $vent_ids->{'liddn'}, $vent_ids->{'indicator'});
      $indicator = '' if (!defined($indicator));
      # Set the topic for the mqtt in nodes
      $filter .= " | if (.name != null) and (.name | contains(\"/${vent}-fan-mqtt/\")) then .topic = \"RVC/DC_DIMMER_STATUS_3/$fan\" else . end";
      $filter .= " | if (.name != null) and (.name | contains(\"/${vent}-lid-mqtt/\")) then .topic = \"RVC/DC_DIMMER_COMMAND_2/$lidup\" else . end";
      # Set the topic for the switch nodes
      $filter .= " | if (.name != null) and (.name | contains(\"/${vent}-fan-sw/\")) then .topic = \"$fan\" else . end";
      $filter .= " | if (.name != null) and (.name | contains(\"/${vent}-lid-sw/\")) then .topic = \"$lidup $liddn $indicator\" else . end";

      # Add devices to Alexa
      my $vent_name = $vent_habridge_names{$vent};
      create_habridge_device(5, $fan, "$vent_name Fan", "vent_fan_new.pl", "2 $fan", "3 $fan");
      create_habridge_device(5, $lidup, "$vent_name Vent", "vent_lid.pl", "69 $lidup $liddn $indicator", "133 $lidup $liddn $indicator");
    }
  }
} else {
  # No vents found
  push @tags, qw(/ventfan-galley/ /ventfan-mid/ /ventfan-rear/);
}

# Delete vent fan/lid controls if there's no rear bath
our @onebath = ('31_MA', '31_SA', '32_SA', '32_CA', '33_AA', '34_TGA', '34_PA', '34_TGA', '35_QBA', '36_GH', '36_QSA', '37_AP', '37_PA', '38_QBA', '40_AH', '40_AP', '40_QKH');
if (grep(/^$floorplan$/, @onebath)) {
  push @tags, qw(/ventfan-rear/);
}

##########################################################
#
# Update door locks
#
##########################################################

# Find the lock IDs for this year, model, and floor plan
my $locks = $json->{$year}{$model}{'Default'}{'Locks'};
if ($locks) {
  if ($locks == 1) {
    # 2015-2018 lock controls are configured by default in flows_coachproxy.json
    create_habridge_device(7, 1, 'Door Lock', "locks.pl 1", 1, 0);
    create_habridge_device(7, 6, 'Cargo Locks', "locks.pl 6", 1, 0);
    create_habridge_device(7, 0, 'All Locks', "locks.pl 0", 1, 0);
  } else {
    # 2019+ locks need to have IDs updated in the UI buttons.
    my $unlock_all = "";
    my $lock_all = "";
    my $misc_args = "--command 1 --duration 1";
    foreach my $lock (keys %{$locks}) {
      my $lock_id   = $locks->{$lock}[0];
      my $unlock_id = $locks->{$lock}[1];
      my $unlock_args = "--id $unlock_id --reverse $lock_id ";
      my $lock_args   = "--id $lock_id --reverse $unlock_id ";

      $filter .= " | if (.name != null) and (.name | contains(\"/${lock}-unlock/\")) then .payload = \"$unlock_args $misc_args\" else . end";
      $filter .= " | if (.name != null) and (.name | contains(\"/${lock}-lock/\")) then .payload = \"$lock_args $misc_args\" else . end";
      $unlock_all .= $unlock_args;
      $lock_all   .= $lock_args;

      create_habridge_device(7, $unlock_id, "$lock lock", "dc_dimmer_pair.pl", "$lock_args $misc_args", "$unlock_args $misc_args");
    }
    # Update the "All Locks" buttons with both sets of IDs
    $filter .= " | if (.name != null) and (.name | contains(\"/all-unlock/\")) then .payload = \"$unlock_all $misc_args\" else . end";
    $filter .= " | if (.name != null) and (.name | contains(\"/all-lock/\")) then .payload = \"$lock_all $misc_args\" else . end";

    create_habridge_device(7, 0, "all locks", "dc_dimmer_pair.pl", "$lock_all $misc_args", "$unlock_all $misc_args");
  }
} else {
  push @tags, qw(/locks/);   # No locks found
}

##########################################################
#
# Misc Features
#
##########################################################

# Water pump
my $pump_id = $json->{$year}{$model}{'Default'}{'Pump'};
$filter .= " | if (.name != null) and (.name | contains(\"/pump_in/\")) then .topic = \"RVC/DC_DIMMER_STATUS_3/$pump_id\" else . end";
$filter .= " | if (.name != null) and (.name | contains(\"/pump_out/\")) then .topic = \"${pump_id}_state\" else . end";
create_habridge_device(0, $pump_id, 'Water Pump', "dc_dimmer.pl $pump_id", 2, 3);

# Fuel water heater
my $fuelheat_id = $json->{$year}{$model}{'Default'}{'Fuelheat'};
if ($fuelheat_id && $fuelheat_id > 0) {
  $filter .= " | if (.name != null) and (.name | contains(\"/fuelheat_in/\")) then .topic = \"RVC/DC_DIMMER_STATUS_3/$fuelheat_id\" else . end";
  $filter .= " | if (.name != null) and (.name | contains(\"/fuelheat_out/\")) then .topic = \"${fuelheat_id}_state\" else . end";
  create_habridge_device(0, $fuelheat_id, 'Diesel Aquahot', "dc_dimmer.pl $fuelheat_id", 2, 3);
} else {
  push @tags, '/fuelheat_out/';
}

# Electric water heater.
# High-end 2018+ coaches also use an AC_LOAD_COMMAND call when turning on the
# electric Aqua-Hot (in addition to DC_DIMMER_COMMAND_2).
my $elecheat_id = $json->{$year}{$model}{'Default'}{'Elecheat'};
my $elecheat_ac_id = $json->{$year}{$model}{'Default'}{'Elecheat_AC'};
if ($elecheat_id && $elecheat_id > 0) {
  $filter .= " | if (.name != null) and (.name | contains(\"/elecheat_in/\")) then .topic = \"RVC/DC_DIMMER_STATUS_3/$elecheat_id\" else . end";
  $filter .= " | if (.name != null) and (.name | contains(\"/elecheat_out/\")) then .topic = \"${elecheat_id}_state\" else . end";

  if ($elecheat_ac_id && $elecheat_ac_id > 0) {
    # TO DO: Edit the AC load ID in the future if/when it changes.
    # For now, it's always 210 and is hardcoded into flows_coachproxy-template.json
    create_habridge_device(0, $elecheat_id, 'Electric Aquahot', "dc_ac_combo.pl $elecheat_id $elecheat_ac_id", 2, 3);
  } else {
    push @tags, '/elecheat_out_ac/';
    create_habridge_device(0, $elecheat_id, 'Electric Aquahot', "dc_dimmer.pl $elecheat_id", 2, 3);
  }
} else {
  push @tags, '/elecheat_out/';
}

# VanLeigh trailers have an electric holding tank heater
my $tankheat_id = $json->{$year}{$model}{'Default'}{'Tankheat'};
if ($tankheat_id && $tankheat_id > 0) {
  $filter .= " | if (.name != null) and (.name | contains(\"/tankheat_in/\")) then .topic = \"RVC/DC_DIMMER_STATUS_3/$tankheat_id\" else . end";
  $filter .= " | if (.name != null) and (.name | contains(\"/tankheat_out/\")) then .topic = \"${tankheat_id}_state\" else . end";
  create_habridge_device(0, $tankheat_id, 'Tank Heater', "dc_dimmer.pl $tankheat_id", 2, 3);
} else {
  push @tags, '/tankheat_out/';
}

# Aqua-Hot Engine Pre-Heat
my $preheat_id = $json->{$year}{$model}{'Default'}{'Preheat'};
if ($preheat_id && $preheat_id > 0) {
  $filter .= " | if (.name != null) and (.name | contains(\"/preheat_in/\")) then .topic = \"RVC/DC_DIMMER_STATUS_3/$preheat_id\" else . end";
  $filter .= " | if (.name != null) and (.name | contains(\"/preheat_out/\")) then .topic = \"${preheat_id}_state\" else . end";
} else {
  push @tags, '/preheat_out/';
}

##########################################################
#
# Final steps
#
##########################################################

# Remove nodes with selected tags
my $taglist = join ' ', @tags;
system("/coachproxy/configurator/node_remover.pl $filename $taglist");

# Update nodes with new IDs, names, etc.
$filter = "[ $filter ]";
system("jq '$filter' < $filename > /tmp/node_changer_temp");
system("mv /tmp/node_changer_temp $filename");
