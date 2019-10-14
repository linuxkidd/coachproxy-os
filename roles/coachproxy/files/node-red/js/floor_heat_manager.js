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

// Manually manages the floor heat level in 2017+ coaches that only have 1-5
// levels provided by Tiffin/Spyder. If a user selects a temperature between
// the standard levels, CoachProxy will raise and/or lower the level as needed
// to maintain the desired intermediate temperature.

var method = global.get('settings2').floor_heat_method;
var instance = msg.payload.instance;
var floor_status = global.get('status').floors[instance];
var ambient_temp = floor_status.measured;
var target_cp_setpoint = parseInt(floor_status.setpoint_cp);
var target_cp_level = (target_cp_setpoint - 68) / 9 + 1;
var current_spyder_setpoint = parseInt(msg.payload['setpoint temp heat F']);
var current_spyder_level = (current_spyder_setpoint - 68) / 9 + 1;
var target_is_standard_level = Number.isInteger(target_cp_level);

// If the user adjusted the floor setting manually via a Spyder keypad,
// use the new value.
if (floor_status.last_cp_setpoint != current_spyder_setpoint) {
    global.set('status.floors[' + instance + '].setpoint', current_spyder_setpoint);
    global.set('status.floors[' + instance + '].setpoint_cp',  current_spyder_setpoint);
    global.set('status.floors[' + instance + '].last_cp_setpoint', current_spyder_setpoint);
    // return { payload: 'Manual change detected. Overriding CP setting.' }
}

// Only manage the floor heat if the floor power is turned on and
// a custom (non-Spyder) temperature setpoint has been selected.
else if (floor_status.power === 1 && !target_is_standard_level) {
    var target_spyder_level;

    // Determine the desired Spyder floor heat level based on the current
    // ambient temperature and the desired temperature. Heat the floor to
    // 1 degree C (1.7 degrees F) above the desired setpoint before turning
    // power off. This replicates the Spyder methodology.
    if (ambient_temp < target_cp_setpoint) {
        target_spyder_level = Math.ceil(target_cp_level);
    } else if (ambient_temp > target_cp_setpoint + 1.7) {
        target_spyder_level = Math.floor(target_cp_level);
    } else {
        target_spyder_level = current_spyder_level;
    }

    if (target_spyder_level != current_spyder_level) {
        var count = Math.abs(current_spyder_level - target_spyder_level);
        var direction = (target_spyder_level < current_spyder_level) ? 'down' : 'up';

        target_spyder_setpoint = (target_spyder_level - 1) * 9 + 68;
        global.set('status.floors[' + instance + '].setpoint', target_spyder_setpoint);
        global.set('status.floors[' + instance + '].last_cp_setpoint', target_spyder_setpoint);
        msg = { payload: method + ' ' + instance + ' ' + direction + ' ' + count };

        return msg;
    }
}
