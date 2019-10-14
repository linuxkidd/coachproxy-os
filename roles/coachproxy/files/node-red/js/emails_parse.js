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

global.set('emails', []);
global.set('emails[0]', msg.payload[0].email0 || "");
global.set('emails[1]', msg.payload[0].email1 || "");

return [
    { external: 1, topic:'email0', payload: global.get('emails')[0] },
    { external: 1, topic:'email1', payload: global.get('emails')[1] }
];
