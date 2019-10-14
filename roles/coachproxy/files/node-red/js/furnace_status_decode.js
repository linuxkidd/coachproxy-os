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

const roofzone = ([0, 2][zone - firstzone - 3]) + firstzone;
const roofstatus = global.get('status').tstat[roofzone] || {};
const roofmode = roofstatus.mode;

var status = {
  mode: mode,
  heatset: heatset,
  coolset: coolset,
  fanmode: fanmode,
  fanspeed: fanspeed
};
global.set('status.tstat[' + zone + ']', status);

var on  = { foreground: 'white', background: '#3D89BE' };
var off = { foreground: 'black', background: '#dddddd' };

var heatstatus = mode == 'heat' ? on : off;
// Off button highlighted if both furnace and heat pump are 'off'
var offstatus = (mode == 'off' && roofmode == 'off') ? on : off;

// Create an array of objects to return from the node's various outputs.
// Most of the parameters are for coloring and updating the button, but
// a payload is also always returned so the RBE node can determine when
// the status has changed.
return [
  Object.assign({ payload: heatstatus.foreground }, heatstatus),
  Object.assign({ payload: offstatus.foreground }, offstatus),
]

