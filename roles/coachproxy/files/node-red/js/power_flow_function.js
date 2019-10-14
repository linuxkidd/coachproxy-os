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

// Set variables used in the advanced power flow diagram and update the
// diagram template node. Variables updated include the battery voltages,
// battery icons, power flow direction icons and colors, and charger amps.
//
// Inputs to this function are discarded, and are only used to trigger an
// update of the diagram template node. Actual values are read from
// global context.
var payload = {};

payload.charger_state = global.get('status').power.charger_state;
payload.inverter_state = global.get('status').power.inverter_status;
payload.house_volts = global.get('status').power.house_battery_volts;
payload.chassis_volts = global.get('status').power.chassis_battery_volts;

// Choose battery icons and colors
var colors = { 0: '#9F292C', 1: '#9F292C', 2:'#EAA626', 3: '#5187BA', 4: '#5187BA'};
var battery_level;

// Convert voltage to a 0-4 value.
battery_level = Math.max(0, Math.min(4, Math.trunc(payload.house_volts / 0.3 - 38)));
payload.house_icon = 'fa-battery-' + battery_level;
payload.house_color = colors[battery_level];

battery_level = Math.max(0, Math.min(4, Math.trunc(payload.chassis_volts / 0.3 - 38)));
payload.chassis_icon = 'fa-battery-' + battery_level;
payload.chassis_color = colors[battery_level];

// Tweak some RV-C labels
if (payload.charger_state == 'undefined' || payload.charger_state == 'do not charge') {
  payload.charger_state = 'charger off';
} else {
  payload.charger_state += ' charge';  // e.g. "Float charge"
}

// Set the charger <-> house variables
var dc_amps = global.get('status').power.inverter_dc_amps;
if (dc_amps < 0) {
    // Charging
    payload.inverter_amps = "+" + -dc_amps;
    payload.house_flow = "fa-lg fa-angle-double-down faa-falling";
    payload.house_flow_color = colors[4];
} else if (dc_amps > 0) {
    // Inverting
    payload.inverter_amps = "-" + dc_amps;
    payload.house_flow = "fa-lg fa-angle-double-up faa-falling-reverse";
    payload.house_flow_color = colors[2];
} else {
    // Idle
    payload.inverter_amps = "0";
    payload.house_flow = 'fa-bars';
    payload.house_flow_color = "#888";
}

// Set the house <-> chassis variables
payload.chassis_flow = 'fa-bars';
payload.chassis_flow_color = "#888";

if (global.get('status').power.battery_merge === true) {
    payload.chassis_flow_color = colors[4];
    payload.chassis_flow = "fa-lg fa-angle-double-down faa-falling";
    if (payload.charger_state == 'charger off' && payload.chassis_volts > 13 && payload.house_volts > 12.8) {
        payload.chassis_flow = "fa-lg fa-angle-double-up faa-falling-reverse";
    }
}

return { payload: payload };
