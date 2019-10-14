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

// Input: the JSON output of DC_DIMMER_STATUS_3/# for a roof fan.
// Output 1: "on" or "off" payload to set toggle switch indicator.
// Output 2: text for display next to the vent/fan name/status.
//
// Also saves the on/off status and brightness into global 'status'
// context for use by other nodes.

var commands = { 'on': 2, 'off': 3 };

var instance = msg.instance;
var brightness = msg.payload['operating status (brightness)'];

var status = brightness > 0 ? 'on' : 'off';
var command = commands[status];

global.set('status.fans[' + instance + ']', status);
var msg1 = { 'payload': command };

return msg1;
