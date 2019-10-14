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

var form = global.get('form.preset');
var number = form.item;
var preset = { name: '' };

if (number > 0) {
  // Save preset to database
  var preset_data = JSON.stringify(preset);
  var newmsg = {};
  newmsg.topic = 'INSERT OR REPLACE INTO presets (number, data) VALUES(?, ?)';
  newmsg.payload = [number, preset_data];

  // Update global context. Converting to JSON and
  // back works around saving a reference to the
  // current values (e.g. 'preset.lights') instead
  // of the desired values.
  var data = JSON.parse(preset_data);
  global.set('presets[' + number + ']', data);

  return [ newmsg, {} ];
}
