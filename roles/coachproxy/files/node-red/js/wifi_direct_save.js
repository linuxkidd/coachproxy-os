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

// Get the saved form data
const apname = global.get('form').apname || '';
const appass = global.get('form').appass || '';

// Save settings to database
var newmsg = {};

if (appass.length < 8) {
  return [ null, { payload: 'Password too short. Aborted.' } ]
} else {
  // Reset the saved form data
  global.set('form.appass', '');

  newmsg.topic = 'UPDATE SETTINGS SET `apname`=?, `appass`=?';
  newmsg.payload = [apname, appass];
  return [ newmsg, { payload: 'Settings saved...'} ];
}
