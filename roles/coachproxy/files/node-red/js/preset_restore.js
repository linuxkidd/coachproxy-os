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

// Replay a saved preset

var number = msg.topic;
var preset = global.get('presets')[number];

if (preset) {

  // Lights
  var light_msg = [];
  if (preset.lights) {
    let commands = { 'dim': 0, 'on': 2, 'off': 3 };
    for (let id in preset.lights) {
      let light = preset.lights[id];
      let brightness = light.brightness;
      let command;
      command = brightness > 95 ? commands['on'] : commands['dim'];
      command = light.state == 'off' ? commands['off'] : command;
      let msg = { payload: id + ' ' + command + ' ' + brightness };
      light_msg.push(msg);
    }
  }

  // Thermostats
  var tstat_msg = [];
  var tstat_furnace_zone = parseInt(global.get('settings2').tstat_first_zone) + 3;
  if (preset.tstat) {
    for (let id in preset.tstat) {
      let tstat = preset.tstat[id];
      if (tstat) {
        // Set the thermostat mode. If it was saved as 'fan only', then set
        // the mode to 'off' and deal with the fan later.
        if (tstat.mode) {
          let msg = '';
          if (tstat.mode == 'fan only') {
            msg = { payload: id + ' off' };
          } else {
            msg = { payload: id + ' ' + tstat.mode };
          }
          tstat_msg.push(msg);
        }

        // Some settings are only for the roof units
        if (id < tstat_furnace_zone) {

          // If there's a temperature setpoint, restore it.
          if (tstat.heatset && tstat.heatset > 0) {
            let msg = { payload: id + ' set ' + tstat.heatset };
            tstat_msg.push(msg);
          }

          // If there's fan mode information, resore it.
          if (tstat.fanmode) {
            let cmd = '';
            if (tstat.fanmode == 'auto') {
              cmd = 'auto';
            } else {
              let commands = { 0: 'auto', 50: 'low', 100: 'high' };
              cmd = commands[tstat.fanspeed];
            }

            let msg = { payload: id + ' ' + cmd + ' ' + tstat.mode };
            tstat_msg.push(msg);
          }
        }
      }
    }
  }

  //var floor_msg = [];
  //if (preset.floors) {
    //let method = global.get('floor_heat_method');
    //for (let id in preset.floors) {

    //}
  //}

  return [light_msg, tstat_msg, null, null];
}

