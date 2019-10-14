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

var topic_parts=msg.topic.split('/');
var payload_parts=msg.payload.split(',');

var msg1={
    'type': 'battery',
    'topic': topic_parts[1],
    'payload': payload_parts[0],
    'external': 1,
    'pkttime': payload_parts[1],
};

return msg1;
