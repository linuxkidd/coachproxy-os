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

// Once a user chooses a notification type when creating a new rule, populate
// the submenus (test case, test value) with sensible options and default values.

const values = { 'tank': '67', 'batt': '11.8', 'temp': '85', 'wet': '40' };
const units = { 'tank': '%', 'batt': 'V', 'temp': 'ºF', 'wet': 'ºF' };
const tests = { 'tank': 'is above', 'batt': 'is below', 'temp': 'is above', 'wet': 'is below' };

var msg_value = { topic: 'notif_value' };
var msg_unit  = { topic: 'notif_unit' };
var msg_test  = { topic: 'notif_test', payload: "is above" };

msg.topic = null; // Required to block existing topic from passing through

// Update default value, unit, and test for numeric rules
for (let key in values) {
  if (msg.payload && msg.payload.toLowerCase().includes(key)) {
    msg_test.options = ['is above', 'is below'];
    msg_test.payload = tests[key];
    msg_value.payload = values[key];
    msg_value.enabled = true;
    msg_unit.payload = units[key];
  }
}

// Update menus for non-numeric rules (e.g. Ignition)
const toggles = ['AC Power', 'Ignition', 'Generator'];
if (toggles.includes(msg.payload)) {
  msg_test.options = ['changes'];
  msg_test.payload = 'changes';
  msg_value.payload = '';
  msg_value.enabled = false;
  msg_unit.payload = '';
}

return [msg_value, msg_unit, msg_test];
