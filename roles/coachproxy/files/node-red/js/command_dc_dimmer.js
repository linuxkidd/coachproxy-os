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

// Input: the on/off or brightness payload from a light switch or slider.
// Output: command line parameters for the dc_dimmer.pl command to actuate the light.

var instance = msg.topic.split('_')[0];
var msgtype = msg.topic.split('_')[1];
var commands = { 'dim': 0, 'on': 2, 'off': 3 };

var command = commands['on'];
var brightness = 100;

if (msgtype == 'state') {
  command = commands[msg.payload];
} else if (msgtype == 'brightness') {
  brightness = msg.payload;
  if (brightness > 0) {
    command = commands['dim'];
  }
}

var newMsg={
  'payload': instance + ' ' + command + ' ' + brightness
};

return newMsg;

