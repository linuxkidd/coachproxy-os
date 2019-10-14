#!/bin/bash
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

# link_quality.sh
# Look up the WiFi link quality information and print the results.
#
# example iwconfig output: Link Quality=63/70    Signal level=-47 dBm

INFO=$(/sbin/iwconfig wlan0 | grep 'Link Quality')
QUALITY=0
if [[ "$INFO" == *"/"* ]]; then
  QUALITY=$(echo $INFO | awk '{ split($0, a, "=| "); split(a[3], b, "/"); printf("%d", b[1]/b[2]*100); }')
fi

echo "$QUALITY"
