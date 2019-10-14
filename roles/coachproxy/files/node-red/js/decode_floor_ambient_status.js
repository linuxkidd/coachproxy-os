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

// Decodes THERMOSTAT_AMBIENT_STATUS messages for floor heat zones.
// Saves the current floor temperature into global context and returns
// it as the payload to display in the UI

var instance = msg.payload.instance;
var zones = { 0: 'Front', 1: 'Rear' };

if (instance in zones) {
    var temp = msg.payload['ambient temp F'];
    global.set('status.floors[' + instance + '].measured', temp);
    return { payload: temp, zone: zones[instance] };
}
