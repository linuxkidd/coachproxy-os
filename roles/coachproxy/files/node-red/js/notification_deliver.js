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

// Pushover message

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

// Email message

let smtp_host = global.get('settings2')['smtp_host'];
let smtp_port = global.get('settings2')['smtp_port'];
let smtp_user = global.get('settings2')['smtp_user'];
let smtp_pass = global.get('settings2')['smtp_password'];

let transport = {};
transport.host = smtp_host;
transport.port = smtp_port;
transport.auth = {};
transport.auth.user = smtp_user;
transport.auth.pass = smtp_pass;

let email1 = global.get('settings2')['notify_email1'];
let email2 = global.get('settings2')['notify_email2'];

let options = {};
options.from = smtp_user;
options.subject = msg.subject;
options.text = msg.payload;

// If the user only added email2, change it to email1
if (email2 && !email1) {
    email1 = email2;
    email2 = '';
}

if (email1) {
    options.to = email1;
    if (email2) {
        options.to += ',' + email2;
    }

  email_msg = { 'mail': { 'transport': transport, 'options': options } };
}

// Deliver

return [msg, push_msg, email_msg];
