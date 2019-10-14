//
// Copyright (C) 2019 Wandertech LLC
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

networks=[{"-Select Network Here-":"Fill in Name"}];
seen={};

msg.payload.sort(function(a, b) {
  return parseFloat(b.signal_level) - parseFloat(a.signal_level);
});

const apssid = global.get('status').network.AP.SSID || '';
seen[apssid] = 1;

for (var i=0;key=msg.payload[i];i++) {
  if (msg.payload[i].ssid !== "" && !seen[msg.payload[i].ssid]) {
    networks.push(msg.payload[i].ssid);
    seen[msg.payload[i].ssid] = 1;
  }
}

return [{'options':networks,'payload':"Fill in Name"},{'payload':"Scan Complete"}];
