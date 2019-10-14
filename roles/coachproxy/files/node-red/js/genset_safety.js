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

if(!msg.hasOwnProperty('timer')) {
    if(msg.topic=='genstartenable') {
        if(msg.payload=="1") {
            global.set('genstartenabletimer', 5);
            global.set('genstartenable', 1);
        } else {
            global.set('genstartenabletimer', 5);
            global.set('genstartenable', 0);
        }
    } else {
        if(msg.topic=='generator' && global.get('genstartenable')===1 ) {
            const version = global.get('settings2').generator_version;
            msg.payload = version + ' ' + msg.payload;
            return msg;
        }
    }
}
