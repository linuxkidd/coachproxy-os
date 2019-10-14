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

var external=0;
if(msg.hasOwnProperty('external'))
    external=msg.external;

global.set('emailsb', global.get('emails') || []);

if(external===0) {
    var emails=global.get('emails');
    if(msg.topic=='commit') {
        if(msg.payload=='save') {
            msg.topic = '';
            return [ {
                topic: 'update notifications set `email0`=?, `email1`=?',
                payload:global.get('emailsb')
                }, {payload:"Saved"}, null];
        } else if (msg.payload=='undo') {
            return [ null, {payload:"Reverted to Saved Values"}, {}];
        }
    } else {
        if(msg.topic=='email0')
            global.set('emailsb[0]', msg.payload);
        if(msg.topic=='email1')
            global.set('emailsb[1]', msg.payload);
    }
}
