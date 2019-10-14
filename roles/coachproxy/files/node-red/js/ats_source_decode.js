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

// Output 1: name of current ATS power source

const genset_status = global.get('status').power.generator_state || 'stopped';

// If the rmsc value is not numeric (e.g. 'n/a'), then
// the ATS is not receiving any external power.
if (isNaN(parseFloat(msg.payload['rms current']))) {
    msg.payload = 'None';
} else if (genset_status == 'running') {
    msg.payload = 'Generator';
} else {
    msg.payload = 'Shore';
}

msg.type = 'acsource';
return msg;
