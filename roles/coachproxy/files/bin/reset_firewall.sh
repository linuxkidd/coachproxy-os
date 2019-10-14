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

iptables -F
iptables -t nat -F

iptables -A INPUT -i tun0 -s 10.255.0.0/22 -j ACCEPT

for m in wlan0 eth0; do
  for i in 22 53 67 68 80 443 1880 1883 1900 8080 50000; do
    for j in tcp udp; do
      iptables -A INPUT -i $m -p $j --dport $i -j ACCEPT
    done
  done
  iptables -A INPUT -i $m -m state --state ESTABLISHED,RELATED -j ACCEPT
  iptables -A INPUT -i $m -j DROP
done

echo 1 > /proc/sys/net/ipv4/ip_forward
