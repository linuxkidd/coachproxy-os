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

if(global.get('genstartenable')===1) {
    if(global.get('genstartenabletimer')<1) {
        global.set('genstartenabletimer', 5);
        global.set('genstartenable', 0);
        return [{
            'topic': 'genstartenable',
            'payload': 0,
            'timer': 1,
        },{countdown: 1, payload:"Controls disabled"}];
    }
    countdown=global.get('genstartenabletimer');
    global.set('genstartenabletimer', global.get('genstartenabletimer') - 1);
    return [null,{countdown: 1, payload:"Controls enabled: "+countdown+" seconds"}];
} else {
    global.set('genstartenabletimer', 5);
    return [{
        'topic': 'genstartenable',
        'payload': 0,
        'timer': 1,
    },{countdown: 1, payload:"Controls disabled"}];
}

