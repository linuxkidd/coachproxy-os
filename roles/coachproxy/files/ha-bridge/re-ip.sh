#!/bin/bash
#
# Copyright 2018 Wandertech LLC
#
# re-ip.sh
# Detects if the system's routable IP address doesn't match the IP
# configured in the habridge.config file (for example, if the CoachProxy
# has been moved to a different network),updates the config file, and
# restarts ha-bridge.

LOG=/coachproxy/bin/cplog.sh
SCRIPT=$(basename $0 .sh)

# Get the network interface (e.g. wlan0, eth0) of the locally routable network
routeIF=$(netstat -rn  | awk '/^0\.0\.0\.0/ {print $NF}' | head -n 1)

# If a network interface was found, get the local IP address of CoachProxy
# and check if the ha-bridge service is enabled.
if [ ! -z $routeIF ]; then
  currentIP=$(ip a | grep "inet .*$routeIF" | grep -v lo$ | awk '{print $2}' | sed -e 's/\/.*$//')
  isenabled=$(systemctl status habridge | grep -c '^ *Loaded.*service; enabled')
fi

# If CoachProxy's current IP address is not in the running habridge.config,
# rebuild the config from the template using the current IP address.
if [ ! -z $currentIP ]; then
  grepPhrase=$(echo $currentIP | sed -e 's/\./\\./g')
  grepPhrase="${grepPhrase}\""

  if [ $(grep -c $grepPhrase /coachproxy/ha-bridge/habridge.config) -eq 0 ]; then
    $LOG "$SCRIPT updating IP address in habridge.config with $currentIP"
    cat /coachproxy/ha-bridge/habridge.config.template | sed -e "s/MYIPADDR/$currentIP/g" > /coachproxy/ha-bridge/habridge.config

    if [ $isenabled -eq 1 ]; then
      sleep 1
      sudo systemctl restart habridge
      $LOG "$SCRIPT restarted habridge.service"
    fi
  fi
fi
