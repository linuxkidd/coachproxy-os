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

// Newer coaches (2018+) report two different sets of
// chassis statuses, identified by F1 or F2 in Byte 0.
// The F1 message includes the ignition status, and the
// F2 message includes the parking brake status.
//
// Older coaches always have 00 in Byte 0 and only report
// ignition status.

const instance = msg.payload.data.substring(0, 2);
msg.topic = null; // Required to block pass-through topic
let newmsg = {};

if (instance == 'F1' || instance == '00') {
  newmsg.topic = 'CP/IGNITION';
  newmsg.payload = msg.payload['ignition switch status'] == '00' ? 'off' : 'on';
  global.set('status.chassis.ignition', newmsg.payload);
} else if (instance == 'F2') {
  newmsg.topic = 'CP/PARKBRAKE';
  newmsg.payload = msg.payload['park brake status'] == '00' ? 'off' : 'on';
  global.set('status.chassis.parkbrake', newmsg.payload);
}

return newmsg;
