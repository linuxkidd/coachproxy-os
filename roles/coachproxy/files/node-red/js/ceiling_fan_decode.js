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

// Input: Payload is the JSON output of DC_DIMMER_STATUS_3/#, and
// msg.instance is either "low" or "high" depending on which dimmer
// is reporting.
//
// Output 1: Text version of the current fan speed.
// Output 2: Numeric version of the current fan speed (0, 1, 2)

var instance = msg.instance;
var brightness = msg.payload['operating status (brightness)'];

// Determine which command was sent.
var level = 0;
if (instance == 'low' && brightness == 100) {
  level = 1;
}
if (instance == 'high' && brightness == 100) {
  level = 2;
}

// Values to display on the text label
var level_names = ['Off', 'Low', 'High'];
var msg1 = {
  'payload': level_names[level]
};

// Set the switch position
var msg2 = {
  'payload': level,
};

return [ msg1, msg2 ];
