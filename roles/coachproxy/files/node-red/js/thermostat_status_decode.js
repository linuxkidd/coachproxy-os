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

const zone     = msg.payload.instance;
const heatset  = parseInt(msg.payload['setpoint temp heat F']);
const coolset  = parseInt(msg.payload['setpoint temp cool F']);
const mode     = msg.payload['operating mode definition'];

const fanspeed = parseInt(msg.payload['fan speed']);
var fanmode    = msg.payload['fan mode definition'];

const furnzone = ([3, -99, 4][zone - firstzone]) + firstzone;
const furnstatus = global.get('status').tstat[furnzone] || {};
const furnmode = 'mode' in furnstatus ? furnstatus.mode : 'off';

const ac_on = global.get('status').tstat[zone].ac_on || false;
const hp_on = global.get('status').tstat[zone].hp_on || false;

var newstatus = {
  mode: mode,
  heatset: heatset,
  coolset: coolset,
  fanmode: fanmode,
  fanspeed: fanspeed,
  ac_on: ac_on,
  hp_on: hp_on
};
global.set('status.tstat[' + zone + ']', newstatus);

if (fanmode == 'on') {
  if (fanspeed == 50) {
    fanmode = 'low';
  } else {
    fanmode = 'high';
  }
}

// Add a symbol to the air conditioner/heat pump label when it's running
var ac_label = ac_on ? '❄︎ A/C' : 'A/C';
var hp_label = hp_on ? '☀︎︎ H.PUMP' : 'H.PUMP';

// Colors for on/off status of buttons
var on  = { foreground: 'white', background: '#3D89BE' };
var off = { foreground: 'black', background: '#dddddd' };

// Off button highlighted if both furnace and heat pump are 'off'
var offstatus = (mode == 'off' && furnmode == 'off') ? on : off;
var coolstatus = mode == 'cool' ? on : off;
var heatstatus = mode == 'heat' ? on : off;
var highstatus = fanmode == 'high' ? on : off;
var lowstatus  = fanmode == 'low' ? on : off;
var autostatus = fanmode == 'auto' ? on : off;

// Create an array of objects to return from the node's various outputs.
// Most of the parameters are for coloring and updating the button, but
// a payload is also always returned so the RBE node can determine when
// the status has changed.
return [
  Object.assign({ payload: coolstatus.foreground + ac_label }, coolstatus, { label: ac_label }),
  Object.assign({ payload: heatstatus.foreground + hp_label }, heatstatus, { label: hp_label }),
  Object.assign({ payload: offstatus.foreground }, offstatus),
  { payload: coolset },
  Object.assign({ payload: highstatus.foreground }, highstatus),
  Object.assign({ payload: lowstatus.foreground }, lowstatus),
  Object.assign({ payload: autostatus.foreground }, autostatus)
]

