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

// format check value
// msg.payload=1431579097;
now=new Date().getTime() / 1000;
diff=Math.floor(now-msg.payload);

outmsg="";
if(diff>86400) {
    days=Math.floor(diff/86400);
    diff-=days*86400;
    if(days>365) {
        years=Math.floor(days/365);
        days-=(years*365);
        outmsg=years+"y ";
    }
    outmsg+=days+"d ";
}
if(diff>3600) {
    hours=Math.floor(diff/3600);
    diff-=hours*3600;
    outmsg+=hours+"h ";
}

if(diff>60) {
    minutes=Math.floor(diff/60);
    diff=0;
    outmsg+=minutes+"m";
} else
    outmsg+="0m";

msg.payload=outmsg;

return msg;
