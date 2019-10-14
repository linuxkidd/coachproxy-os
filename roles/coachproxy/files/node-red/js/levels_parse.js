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

if (global.get('levels') === undefined)
  global.set('levels', {});
global.set('levels.fields', ['Fresh_low', 'Fresh_high', 'Grey_high', 'Black_high', 'LPG_low']);
global.set('levels.fullTanks', ['Grey_full', 'Black_full']);
global.set('levels.subItems', ['clear', 'sent', 'time']);
global.set('levelsb', msg.payload[0]);

outmsg = [];
for (var i = 0; key = global.get('levels').fields[i]; i++) {
  global.set('levels.' + key, msg.payload[0][key]);
  for (var j = 0; subItem = global.get('levels').subItems[j]; j++) {
    if (global.get('levels')[key + '_' + subItem] === undefined) {
      global.set('levels.' + key + '_' + subItem, 0);
    }
  }
  var tmpmsg = {
    'topic': key,
    'payload': msg.payload[0][key],
    'external': 1
  };
  outmsg.push(tmpmsg);
}

for (var i = 0; key = global.get('levels').fullTanks[i]; i++) {
  for (var j = 0; subItem = global.get('levels').subItems[j]; j++) {
    if (global.get('levels')[key + '_' + subItem] === undefined) {
      global.set('levels.' + key + '_' + subItem, 0);
    }
  }
  global.set('levels.' + key, 99);
}

return outmsg;

