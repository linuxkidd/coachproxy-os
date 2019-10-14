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

global.set('levelsb', global.get('levelsb') || {});

var external=0;
if(msg.hasOwnProperty('external'))
    external=msg.external;
/*
return payload:
 0 - SQL
 1 - Update for filtered input
 2 - Message
 3 - Revert
*/

tank_max=99;
tank_min=0;
if(external===0) {
    if(msg.topic=='commit') {
        if(msg.payload=='save') {
        sqltopic='update notifications set `'+global.get('levels').fields.join('`=?, `')+'`=?';
        sqlvalues=[];
        for(i=0;key=global.get('levels').fields[i];i++)
            sqlvalues.push(global.get('levelsb')[key]);
        msg.topic = '';
        return [{
            topic: sqltopic,
            payload: sqlvalues
            },null,{payload:"Saved"},null];
        } else if (msg.payload=='undo') {
            return [ null, null, {payload:"Reverted to Saved Values"}, {}];
        }
    } else {
        payload=msg.payload.replace(/[^0-9\.\-]/g, '');
        if(payload !== '' && payload>tank_max)
            payload=tank_max;
        if(payload !== '' && payload<tank_min)
            payload=tank_min;

        global.set('levelsb.' + msg.topic, payload);
        if(payload!=msg.payload)
            return [null,{},null,null];
    }
}
