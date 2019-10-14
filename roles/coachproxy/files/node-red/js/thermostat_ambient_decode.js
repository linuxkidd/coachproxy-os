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
var tstat_first_zone = parseInt(global.get('settings2').tstat_first_zone) || 0;
var tstat_zone_names = ['Front', 'Mid', 'Rear'];

if (zone >= tstat_first_zone && zone <= tstat_first_zone + 2) {
    data = {};
    data.zone_name = tstat_zone_names[zone - tstat_first_zone];
    data.ambient_temp = msg.payload['ambient temp F'];
    data.ambient_temp = Math.round(data.ambient_temp*10)/10;
    data.unit = 'F';
    msg.payload = data; // Get rid of things that might confuse RBE

    messages = [null, null, null];
    messages[zone - tstat_first_zone] = msg;
    return messages;
}
