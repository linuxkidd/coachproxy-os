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

var zone = msg.payload.instance;
var zone_names = {
  6: 'Wet Bay',
  7: 'Generator Bay'
};
var round = true;

if (zone in zone_names) {
  data = {};
  data.zone_name = zone_names[zone];
  data.ambient_temp = msg.payload['ambient temp F'];
  if (round) {
    data.ambient_temp = Math.round(data.ambient_temp*2)/2;
  }
  data.unit = 'F';
  msg.payload = data; // Get rid of things that might confuse RBE

  messages = [null, null];
  messages[zone - 6] = msg;

  return messages;
}
