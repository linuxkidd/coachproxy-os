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

# coachproxy_watchdog.sh
# Should be run from cron every minute to ensure that things are
# working properly.

LOG=/coachproxy/bin/cplog.sh
SCRIPT=$(basename $0 .sh)

# If canbus is down, keep trying to bring it up.
WASDOWN=0
while [ $(ip a | grep can0 | grep -c DOWN) -gt 0 ]; do
  $LOG "$SCRIPT can0 is DOWN. Attempting to restart..."
  WASDOWN=1
  sudo /sbin/ip link set can0 up type can bitrate 250000
  sleep 5
done

if [ $WASDOWN -eq 1 ]; then
  $LOG "$SCRIPT can0 interface is now up."
fi

# If rvc2mqtt.pl is down, start it in background.
if [ -z $(/bin/pidof -x rvc2mqtt.pl) ]; then
  $LOG "$SCRIPT rvc2mqtt.pl is down. Starting it..."
  /coachproxy/bin/rvc2mqtt.pl &> /dev/null &
fi

# Start WiFi MQTT publisher if it's not running.
if [ $(/bin/pidof -x wifi_mqtt.pl | wc -w) -eq 0 ]; then
  $LOG "$SCRIPT wifi_mqtt.pl is down. Starting it..."
  /coachproxy/bin/wifi_mqtt.pl &> /dev/null &
fi

# If ngrok tunnel is down but should be up, try starting it.
enabled=$(echo "select value from settings2 where key='remote_access';" | sqlite3 /coachproxy/node-red/coachproxy.sqlite)
if [[ $enabled == 'true' ]]; then
  if [ -z $(/bin/pidof -x ngrok) ]; then
    $LOG "$SCRIPT ngrok tunnel is down. Attempting restart..."
   /coachproxy/bin/apply_remote_access_settings.sh --silent &> /dev/null &
  fi
fi

# Delete old lock files in case scripts failed and didn't clean up
sudo find /tmp -name wifi_watchdog.lock -mmin +30 -delete
