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

# wifi_mqtt.pl
# Look up information about the current WiFi state and publish it to MQTT
# every second. This runs as a forever loop, and should be monitored and
# restarted if it exits.

use strict;
use warnings;
use Switch;
use Wifi::WpaCtrl;
use Net::MQTT::Simple "localhost";
use JSON;
no strict 'refs';

while (1) {
  my $tstamp = time;

  # wlan0 ("Your WiFi Network")
  my %wlan0_status = map { split /=|\n+/; } `/sbin/wpa_cli -i wlan0 status`;
  my $wlan0_ssid = $wlan0_status{ssid} || '';
  my $wlan0_ip = $wlan0_status{ip_address} || '';
  my $wlan0_gw = `ip route | grep default | cut -f3 -d' '`;
  chomp($wlan0_gw);
  retain "NETWORK/WPA/SSID" => "$wlan0_ssid";
  retain "NETWORK/WPA/IP" => "$wlan0_ip";
  retain "NETWORK/WPA/STATE" => "$wlan0_status{wpa_state}" if ($wlan0_status{wpa_state});
  retain "NETWORK/WPA/MAC" => "$wlan0_status{address}" if ($wlan0_status{address});
  retain "NETWORK/WPA/GW" => "$wlan0_gw";

  # WiFi Link Quality
  my $wpa_linkinfo = `/coachproxy/bin/wifi_link_quality.sh`;
  if ( $wpa_linkinfo =~ /(\d+)/ ) {
    retain "NETWORK/WPA/QUALITY" => "$1";
  }

  sleep 1;
}
