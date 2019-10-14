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

// Input: the JSON output of DC_DIMMER_STATUS_3/# for a light.
// Output 1: "on" or "off" payload to set toggle switch indicator.
// Output 2: brightness level (0-100) to set optional slider value.
//
// Also saves the on/off status and brightness into global 'status'
// context for use by other nodes.
//
// Built-in RBE functionality only outputs messages if the value has
// changed from the previously recorded value.

var instance = msg.payload.instance;
var brightness = msg.payload['operating status (brightness)'];

var previous = global.get('status').lights[instance];
var command = (brightness > 0) ? 'on' : 'off';

var msg1 = null;
var msg2 = null;

// Only send a message if the value has changed.
if (previous.state != command) {
  if (previous) {
    global.set('status.lights[' + instance + '].state', command);
  }
  msg1 = { 'payload': command };
}

if (previous.brightness != brightness && brightness <= 100) {
  global.set('status.lights[' + instance + '].brightness', brightness);
  msg2 = { 'payload': brightness };
}

return [ msg1, msg2 ];

