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

// Monitor certain MQTT topics for a change in state (e.g. "ignition"
// changing from "off" to "on") and send a notification. If too many
// notifications are sent within a short time, enter a long "backoff"
// phase where no notifications for the topic will be sent.

const topics = {
  'Ignition': 'CP/IGNITION',
  'Park Brake': 'CP/PARKBRAKE',
  'Generator': 'CP/GENERATOR',
  'AC Power': 'CP/AC_SOURCE',
};

// Pause for <pause_time> if <max_messages> are sent in <max_interval> for a topic.
// Defaults: Pause for 60 minutes if 8 messages are sent within 5 minutes
const pause_time = 60 * 60 * 1000;
const max_messages = 8;
const max_interval = 5 * 60 * 1000;

let notifs = global.get('settings2')['notify_rules'] || [];
let newmsg = null;

// Check each notification rule
for (let notif in notifs) {
  let n = notifs[notif];

  // If the current message topic matches a notification rule, process the rule
  if (topics[n.notif_type] == msg.topic) {

    // Look up the previous state of this topic. If this is the first time
    // receiving a message for the topic, set it to the current state to
    // prevent sending an alarm each time CoachProxy starts up.
    let prev_state = n.notif_state || msg.payload;

    // Look up the count of alarms sent recently for this topic
    let count = n.notif_count || 0;

    // Look up the start of the current backoff interval
    let interval_start = n.notif_interval || Date.now();

    // If notifications are paused, see if it's time to release them
    if (n.notif_pause && Date.now() - n.notif_pause > pause_time) {
      n.notif_pause = null;
    }

    // If the current interval is over, clear it out
    if (Date.now() - interval_start > max_interval) {
      count = 0;
      n.notif_count = 0;
      n.notif_interval = null;
    }

    // Alarm if the current value is different from the previous value.
    if (msg.payload != prev_state && !n.notif_pause) {
      count++;

      // If it's over its threshold, start the pause clock, otherwise send alarm.
      if (count > max_messages) {
        newmsg = {};
        newmsg.payload = 'Too many notifications being sent for ' + n.notif_type + '. ';
        newmsg.payload += 'Pausing for ' + (pause_time / 60 / 1000) + " minutes.\n";
        newmsg.subject = 'CoachProxy ALERT for ' + n.notif_type;

        n.notif_pause = Date.now();
        n.notif_count = 0;
        n.notif_interval = null;
      } else {
        newmsg = {};
        newmsg.payload = n.notif_type + ' has changed from ' + prev_state + ' to ' + msg.payload + ".\n";
        newmsg.subject = 'CoachProxy ALERT for ' + n.notif_type;

        if (count == 1) {
          n.notif_interval = Date.now();
        }
        n.notif_count = count;
      }
    }

    // Update the latest state
    n.notif_state = msg.payload;
  }
}

return newmsg;
