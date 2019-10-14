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

// Calculate the tank percent full and republish it to the "CP/" topic.

let newmsg = {};
msg.topic = null; // Required to block pass-through topic

let pct_full = Math.round(msg.payload['relative level'] / msg.payload.resolution * 100);

const labels = ['Fresh', 'Black', 'Grey', 'LPG'];

newmsg.topic = 'CP/TANK_STATUS/' + labels[msg.payload.instance];
newmsg.payload = pct_full;

return newmsg;
