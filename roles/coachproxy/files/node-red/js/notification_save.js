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

// After the user has defined a new notification rule, save it to the
// database.

var notifs = global.get('settings2')['notify_rules'] || [];
var notif = {};

const topics = [
    'notif_type',
    'notif_test',
    'notif_value',
    'notif_unit'
];

topics.forEach(function(topic) {
  const value = global.get('form')[topic] || '';
  notif[topic] = value;
});

// If a value is required but not present, give up.
if (notif['notif_test'] != 'changes' && (notif['notif_value'] === '' || isNaN(notif['notif_value']))) {
  msg = null;
} else {
  notifs.push(notif);
  notifs.sort((a,b) => a.notif_type.localeCompare(b.notif_type));

  // Delete "notif_state" for existing toggle rules (e.g. "generator") so
  // their current state doesn't get saved to the database along with the rule.
  notifs.forEach(function(n) {
    delete n.notif_state;
  });

  msg = { topic: 'notify_rules', payload: JSON.stringify(notifs) };
}

return msg;

