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

# apply_remote_access_settings.sh
# Read the Remote Access settings from the sqlite database, update
# the ngrok.conf file with the new values, and stop or start the
# tunnel.

log=/coachproxy/bin/cplog.sh
script=$(basename $0 .sh)
conf=/coachproxy/etc/ngrok.conf

log () {
  if [[ "$silent" = false ]]; then
    $log "$script $1 Stopping ngrok tunnel."
  fi
}

send_message () {
  /usr/local/bin/mqtt-simple -h localhost -p "CP/MESSAGE/REMOTEACCESS" -m "$1"
}

disable () {
  result=$(echo "INSERT OR REPLACE INTO settings2 (key, value) VALUES('remote_access', 'false')" | sqlite3 /coachproxy/node-red/coachproxy.sqlite)
}

abort () {
  send_message "$1"
  echo "$1"
  log "$script $1 Stopping ngrok tunnel."
  sudo killall ngrok
  disable
  exit 0;
}

silent=false
if [[ $1 == "--silent" ]]; then
  silent=true
else
  send_message "Applying remote access settings..."
fi

# Wait a second to ensure node-red finishes updating the database
sleep 1

# Get the settings from the database.
user=$(echo "select value from settings2 where key='remote_username';" | sqlite3 /coachproxy/node-red/coachproxy.sqlite)
pass=$(echo "select value from settings2 where key='remote_password';" | sqlite3 /coachproxy/node-red/coachproxy.sqlite)
auth=$(echo "select value from settings2 where key='ngrok_auth';" | sqlite3 /coachproxy/node-red/coachproxy.sqlite)
enabled=$(echo "select value from settings2 where key='remote_access';" | sqlite3 /coachproxy/node-red/coachproxy.sqlite)
domain=$(echo "select value from settings2 where key='remote_subdomain';" | sqlite3 /coachproxy/node-red/coachproxy.sqlite)

if [[ $enabled != 'true' ]]; then
  abort "Remote access is disabled."
fi

if [[ ${#auth} -lt 5 ]]; then
  abort "ERROR: ngrok Authtoken is missing."
fi

if [[ ${#user} -lt 1 ]]; then
  abort "ERROR: Username is missing."
fi

if [[ ${#pass} -lt 1 ]]; then
  abort "ERROR: Password is missing."
fi

# If a custom subdomain is used, bind the main tunnel to https only.
# The secondary tunnel will then be bound to http using the same
# domain name. If a custom subdomain is not used, bind the main tunnel
# to both http and https, since the secondary tunnel will have a
# completely different URL which won't be usable by the user.
bind_tls=true
if [[ ${#domain} -lt 1 ]]; then
  bind_tls=both
fi

# Rebuild config file
log "$script update ngrok.conf with latest user settings"
sed "${conf}-TEMPLATE" -e "s/AUTHTOKEN/$auth/" -e "s/USERNAME/$user/" -e "s/PASSWORD/$pass/" -e "s/BIND_TLS/$bind_tls/" -e "s/SUBDOMAIN/$domain/" > $conf

# Restart tunnel
log "$script restarting ngrok tunnel."
send_message "Restarting remote access system. See above for URL."
sudo killall ngrok
sleep 2
/usr/local/bin/ngrok start -config /coachproxy/etc/ngrok.conf --all &
