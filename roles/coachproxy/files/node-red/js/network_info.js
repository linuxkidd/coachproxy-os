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

// Monitor NETWORK/*/* messages. Save the resulting data to
// global context, and pass the full context to the dashboard.

const topics = msg.topic.split('/');
if (topics.length < 3) {
    return null;
}

const topic = topics[1] + '/' + topics[2];

// Save the new value to global status
global.set('status.network.' + topics[1] + '.' + topics[2], msg.payload);
const network = global.get('status').network;

// Create a package of information for the dashboard template
var message = '';

if (!network || !network.WPA || network.WPA.IP === '') {
    message = "CoachProxy is not connected via WiFi.";
} else {
    message = "CoachProxyOS is connected to the WiFi network listed below.";
}

// The values that will be displayed are in the `data` and other parameters,
// but a payload is also always returned so the RBE node can determine when
// the status has changed.
const rbe = message + network.WPA.SSID + network.WPA.IP + network.WPA.MAC + network.WPA.STATE + network.WPA.QUALITY +
  network.AP.SSID + network.AP.IP

return { payload: rbe, data: network, message: message };
