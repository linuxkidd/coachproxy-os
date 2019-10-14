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

// Populate the "Notification Type" menu with appropriate options
// based on the user's choice of coach and options.

const configs = global.get('configs');
const features = global.get('features')[configs.year][configs.model]['Default'];
const ac_source = global.get('status').power.ac_source;

let options = [];

// Tanks
options.push('Tank: Fresh');
options.push('Tank: Grey');
options.push('Tank: Black');
if (configs.lpg === 'true') {
    options.push('Tank: LPG');
}

// Batteries
options.push('Batt: House');
if (configs.batt_chassis === 'true') {
    options.push('Batt: Chassis');
}

// Temps
if (configs.tstats === 'true') {
    options.push('Temp: Front');
    if (configs.thirdtstat === 'true') {
        options.push('Temp: Mid');
    }
    options.push('Temp: Rear');
    if (configs.exttemp === 'true') {
        options.push('Temp: Wet Bay');
    }
}

// Toggles

if (ac_source) {
  options.push('AC Power');
}
if (features.Ignition == 1) {
    options.push('Ignition');
}
if (features.GeneratorStatus == 1) {
    options.push('Generator');
}

msg = { options: options, payload: null, topic: null };
return msg;

