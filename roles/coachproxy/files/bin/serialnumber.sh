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

# serialnumber.sh
# Determine the CoachProxy serial number based on the ethernet hardware
# address. Return the serial as text and publish it to MQTT.

SERIAL=$(ip a | grep -A1 eth0 | awk '/link\/ether/ {print $2}' | sed -e 's/://g')

# Use a default serial number if the serial is invalid
if [[ ${#SERIAL} -lt 12 ]]; then
  SERIAL='000000000000';
fi

/usr/local/bin/mqtt-simple --host localhost --retain --publish "GLOBAL/SN" --message "$SERIAL"
echo $SERIAL

exit 0
