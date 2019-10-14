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

global.set('genStatTime', global.get('genStatTime') || 0);
if (msg.hasOwnProperty('countdown')) {
    if (global.get('genStatTime')===0 || (new Date().getTime()/1000)-global.get('genStatTime')>5)
        return msg;
    else
        return null;
} else {
    global.set('genStatTime', new Date().getTime()/1000);
    return msg;
}

