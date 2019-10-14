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
const wifiname = global.get('form').wifiname || '';
const wifipass = global.get('form').wifipass || '';

// Reset the saved form data
global.set('form.wifipass', '');

// Save settings to database
var newmsg = {};

newmsg.topic = 'UPDATE SETTINGS SET `wifiname`=?, `wifipass`=?';
newmsg.payload = [wifiname, wifipass];

return [ newmsg, { payload: 'Settings saved...'} ];
