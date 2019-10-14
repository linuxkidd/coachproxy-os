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

// Create command line arguments to set the floor heat temperature or
// level.

var methodyear = global.get('settings2').floor_heat_method;
var method = methodyear.substring(0, 6);
var year = methodyear.substring(6, 10);
var instance = msg.topic;

if (method == 'direct') {
  // Pre-2017 coaches can just set the temperature directly to any level.
  var newMsg = { payload: methodyear + ' ' + instance + ' ' + msg.payload };
  return newMsg;

} else {

  // 2017+ coaches can only set the level to one of five values, via
  // up/down commands.
  //
  // Set the global context variables for the new setpoint and wait for
  // the floor heat manager function to take care of the rest. If the user
  // selected a standard Spyder temperature, set the floors to that level
  // immediately.

  var floor_status = global.get('status').floors[instance];
  var target_cp_setpoint = parseInt(msg.payload);
  var target_cp_level = (target_cp_setpoint - 68) / 9 + 1;
  var current_spyder_level = (floor_status.setpoint - 68) / 9 + 1;
  var target_is_standard_level = Number.isInteger(target_cp_level);

  global.set('status.floors[' + instance + '].setpoint_cp', target_cp_setpoint);

  if (target_is_standard_level && target_cp_level != current_spyder_level) {
      global.set('status.floors[' + instance + '].last_cp_setpoint', target_cp_setpoint);
      var count = Math.abs(current_spyder_level - target_cp_level);
      var direction = target_cp_level > current_spyder_level ? 'up' : 'down';
      var newMsg = { payload: methodyear + ' ' + instance + ' ' + direction + ' ' + count };
      return newMsg;
  }
}
