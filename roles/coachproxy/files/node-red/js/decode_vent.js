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

// Input: the JSON output of DC_DIMMER_COMMAND_2/# for a roof vent.
// Output 1: dimmer command payload to set toggle switch indicator.
//
// Also saves the on/off status and brightness into global 'status'
// context for use by other nodes.

var commands = { 'open': 69, 'closed': 133 };

var instance = msg.instance;
var brightness = msg.payload['desired level'];

var status = brightness > 99 ? 'open' : 'closed';
var command = commands[status];

global.set('status.vents[' + instance + ']', status);
var msg1 = { 'payload': command };

return msg1;
