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

misc = ['ignition', 'generator', 'acpower', 'battery_low'];
global.set('misc', msg.payload[0]);

flags = ['1_battery_low', '2_battery_low'];

for (i = 0; flag = flags[i]; i++) {
    global.set('misc.' + flag + '_sent', global.get('misc')[flag + '_sent'] || 0);
    global.set('misc.' + flag + '_time', global.get('misc')[flag + '_time'] || 0);
}

global.set('ign', global.get('ign') || {});
global.set('ign.lastState', global.get('ign').lastState || 'off');

global.set('gen', global.get('gen') || {});
global.set('gen.lastState', global.get('gen').lastState || 'stopped');
global.set('gen.startEnable', global.get('gen').startEnable || false);
global.set('gen.startEnableTimer', global.get('gen').startEnableTimer || 5);

global.set('acsource', global.get('acsource') || {});
global.set('acsource.lastState', global.get('acsource').lastState || 'Shore');

outmsg = [];
for (var i = 0; key = misc[i]; i++) {
    var tmpmsg = {
        'topic': key,
        'payload': msg.payload[0][key],
        'external': 1
    };
    outmsg.push(tmpmsg);
}

return outmsg;
