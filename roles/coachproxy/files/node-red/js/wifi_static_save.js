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

// Get the saved form data
const staticenabled = global.get('form').dhcp || 0;
const staticip      = global.get('form').ipaddr || '';
const staticmask    = global.get('form').netmask || '';
const staticgw      = global.get('form').gateway || '';

function validateIPaddress(ipaddress) {
  var ipformat = /^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$/;
  return ipaddress.match(ipformat)
}

var error = '';
if (staticenabled == 1) {
  if (! validateIPaddress(staticip)) {
    error = error + 'IP address not valid. ';
  }
  if (! validateIPaddress(staticgw)) {
    error = error + 'Gateway address not valid. ';
  }
  if (! validateIPaddress(staticmask)) {
    error = error + 'Netmask not valid. ';
  }

  if (error.length > 1) {
    return [ null, { payload: error } ];
  }
}

// Save settings to database
var newmsg = {};

newmsg.topic = 'UPDATE SETTINGS SET `dhcp`=?, `ipaddr`=?, `netmask`=?, `gateway`=?';
newmsg.payload = [staticenabled, staticip, staticmask, staticgw];

return [ newmsg, { payload: 'Settings saved...'} ];
