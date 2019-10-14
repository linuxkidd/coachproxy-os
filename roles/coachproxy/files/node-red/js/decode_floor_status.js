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

// Decodes THERMOSTAT_STATUS_1 messages for floor heat zones.
// Saves the current floor temperature into global context and returns
// it as the payload to display in the UI

var methodyear = global.get('settings2').floor_heat_method;
var method = methodyear.substring(0, 6);
var year = methodyear.substring(6, 10);
var instance = msg.payload.instance;
var setpoint = parseInt(msg.payload['setpoint temp heat F']);

global.set('status.floors[' + instance + '].setpoint', setpoint);

var setpoint_cp = global.get('status').floors[instance].setpoint_cp;
var last_setpoint_cp = global.get('status').floors[instance].last_cp_setpoint;

// If this is a pre-2017 coach, or if no custom CoachProxy setpoint has been
// set, set it to the current Spyder setpoint. This is only used in 2017+
// coaches where CoachProxy manages the floor heat manually.
if (method == 'direct' || setpoint_cp === 0) {
    setpoint_cp = setpoint;
    global.set('status.floors[' + instance + '].setpoint_cp', setpoint_cp);
}

var power = msg.payload['operating mode definition'] == 'off' ? 0 : 1;
global.set('status.floors[' + instance + '].power', power);

var power_msg = {
    topic:   instance,
    payload: power
}

var setpoint_msg = {
    topic:   instance,
    payload: setpoint_cp
  };

return [power_msg, setpoint_msg];

