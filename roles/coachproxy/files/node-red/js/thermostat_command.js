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

// Sometimes zone 0 is the front, sometimes it's zone 2 (if heated floors are 0 and 1)
const firstzone = parseInt(global.get('settings2').tstat_first_zone) || 0;

// The zone name (e.g. front) that sent this command
const thiszone = msg.topic;

// Figure out the actual instance ID (0-2)
const instances = ['tstat_front', 'tstat_mid', 'tstat_rear', 'tstat_front_furn', 'tstat_rear_furn'];
const instance = instances.indexOf(thiszone) + firstzone;

const status = global.get('status').tstat[instance];
const current_mode = status.mode;

const fan_buttons = ['off', 'low', 'high'];
const current_fanmode = status.fanmode;
const current_speed = status.fanspeed;
const current_fan_button = fan_buttons[current_speed / 50];

const furnzone = ([3, -99, 4][instance - firstzone]) + firstzone;

var command = msg.payload;
var msgs = [];

// If payload contains a command (not a number)...
if (isNaN(msg.payload)) {
  // Is this a fan command?
  if (fan_buttons.includes(msg.payload)) {
    // Turn off current mode, e.g. "low" pressed while fan already on low.
    if (current_fanmode == 'on' && msg.payload == current_fan_button) {
      command = 'auto';
    }
  } else {
    if (msg.payload == current_mode) {
      // Turn off current mode, e.g. "cool" pressed while already cooling.
      command = 'off';
    } else if (command == 'cool' || command == 'heat') {
      // If heat or cool is being turned on, ensure opposing mode is off for
      // all thermostats. Spyder takes care of this automatically for 2018+
      // models, but in the 2017 VanLeigh Vilano, it's possible to end up with
      // both the air conditioner and furnace on at the same time without this
      // check.
      const disable_mode = (command == 'cool' ? 'heat' : 'cool');
      for (let i = firstzone; i < firstzone + 5; i++) {
        let zonestatus = global.get('status').tstat[i];
        if (zonestatus && zonestatus.mode && zonestatus.mode == disable_mode) {
          msgs.push( { payload: i + ' off' } );
        }
      }
    }
  }
  msgs.push( { payload: [instance, command, current_mode].join(' ') } );

  // If the "off" button was pressed, also turn off the associated
  // furnace for front and rear instances.
  if (msg.payload == 'off' && furnzone >= 0) {
    msgs.push( { payload: [furnzone, command].join(' ') } );
  }
}

// Payload contains a temperature setpoint (a number)...
else {
  msgs.push( { payload: [instance, 'set', msg.payload].join(' ') } );
}

return [msgs];

