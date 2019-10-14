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

// Create global context objects that are used elsewhere
// in flows/functions. This prevents many Javascript warnings
// along the lines of: "TypeError: Cannot read property 'foo' of null"

// To track form fields filled in by users
global.set('form', {});
global.set('form.preset', {});

// To track the current status of various systems
global.set('status', {});
global.set('status.power', {});
global.set('status.fans', {});
global.set('status.vents', {});
global.set('status.lights', {});
global.set('status.chassis', {});
global.set('status.network', { WPA: {}, AP: {} } );

global.set('status.floors', {
  0: { power: 0, setpoint: 68, setpoint_cp: 0, measured: 0 },
  1: { power: 0, setpoint: 68, setpoint_cp: 0, measured: 0 }
});

// Set every light to "off" by default
for (let i = 0; i < msg.lights.length; i++) {
  var light = { state: 'off', brightness: 0 };
  global.set('status.lights[' + msg.lights[i] + ']', light);
}

for (let i = 0; i <= 6; i++) {
  global.set('status.tstat[' + i + ']', {});
}

// Settings

global.set('settings2', {});
global.set('settings2.notify_email1', '');
global.set('settings2.notify_email2', '');
global.set('settings2.pushover_key', '');
global.set('settings2.remote_username', '');
global.set('settings2.remote_subdomain', '');
global.set('settings2.ngrok_auth', '');

// Legacy objects
global.set(['ap', 'ign'], [{}, {}]);

return {};
