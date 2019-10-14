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

// Take a notification message as input, and deliver it via a variety of
// methods based on the user's settings.

let generic_msg = msg;
let push_msg = {};
let email_msg = {};

msg.topic = null;  // Block existing topic from passing through

let pushover_key = global.get('settings2')['pushover_key'];
if (pushover_key) {
    push_msg.headers = { "content-type": "application/x-www-form-urlencoded" };
    push_msg.payload = {
        user: pushover_key,
        token: 'afvtrcguexvtutk7orsc41m1fcw42i',
        title: msg.subject,
        message: msg.payload,
    };
}

let email1 = global.get('settings2')['notify_email1'];
let email2 = global.get('settings2')['notify_email2'];

// If the user only added email2, copy it to email1
if (email2 && !email1) {
    email1 = email2;
    email2 = '';
}

if (email1) {
    email_msg.to = email1;
    if (email2) {
        email_msg.to += ',' + email2;
    }
    email_msg.topic = msg.subject;
    email_msg.payload = msg.payload;
}

return [msg, push_msg, email_msg];
