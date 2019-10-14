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

// Monitor MQTT topics for values that are outside the desired range (e.g.
// battery voltage below 11.8 V). To prevent frequent notifications around
// alarm thresholds (e.g. voltage may fluctuate from 11.7 to 11.8 for a while),
// a value must be out of range (faulted) for a certain time before an alarm
// is sent (triggered), and then must be within the valid range (recovering)
// for a certain time before the alarm is considered cleared.
//
//           good value                           bad value
//      +------------------+                 +------------------------+
//      |                  |    >30 sec      |                        |
//      v      bad         |      bad        v         good           |
// +---------+ value +---------+ value  +-----------+  value   +------------+
// | cleared |------>| faulted |------->| triggered |--------->| recovering |
// +---------+       +---------+        +-----------+          +------------+
//    ^   ^                                  |              good value|
//    |   |             >24 hours            |                  >5 min|
//    |   +----------------------------------+                        |
//    +---------------------------------------------------------------+

const topics = {
  'Tank: Fresh': 'CP/TANK_STATUS/Fresh',
  'Tank: Grey': 'CP/TANK_STATUS/Grey',
  'Tank: Black': 'CP/TANK_STATUS/Black',
  'Temp: Front': 'CP/THERMISTOR_TEMP/Front',
  'Temp: Mid': 'CP/THERMISTOR_TEMP/Mid',
  'Temp: Rear': 'CP/THERMISTOR_TEMP/Rear',
  'Temp: Wet Bay': 'CP/THERMISTOR_TEMP/Wet Bay',
  'Batt: House': 'CP/BATTERY_VOLTS/House',
  'Batt: Chassis': 'CP/BATTERY_VOLTS/Chassis',
};

const fault_timeout   = 30 * 1000;      // receive bad messages for 30 seconds before alarming
const recover_timeout = 5 * 60 * 1000;  // receive good messages for 5 minutes before clearing
const trigger_timeout = 24 * 60 * 60 * 1000; // reset alarm after 24 hours even with bad messages

let notifs = global.get('settings2')['notify_rules'] || [];
let ignition = global.get('status').chassis.ignition || 'off';
let messages = [];

// Check each notification rule
for (let notif in notifs) {
  let n = notifs[notif];
  let status = n.notif_status || 'cleared';

  // If the current message topic matches a notification rule, process the rule.
  // Exception: ignore tanks when the ignition is on.
  if (topics[n.notif_type] == msg.topic && (ignition == 'off' || (msg.topic).includes('TANK') == false)) {

    let oldstatus = status;

    // Check whether the current value is outside the desired range
    let outofrange = false;
    if ((n.notif_test == 'is below' && parseFloat(msg.payload) < parseFloat(n.notif_value)) ||
      (n.notif_test == 'is above' && parseFloat(msg.payload) > parseFloat(n.notif_value))) {
      outofrange = true;
    }

    // Perform actions based on which state the rule is currently in
    switch (status) {
      case 'cleared':
        if (outofrange) {
          status = 'faulted';
          n.fault_time = Date.now();
        }
        break;
      case 'faulted':
        if (!outofrange) {
          status = 'cleared';
        } else if (Date.now() - n.fault_time > fault_timeout) {
          status = 'triggered';
          n.trigger_time = Date.now();
          let message = n.notif_type + ' is currently ' + msg.payload + n.notif_unit;
          message += ' which ' + n.notif_test;
          message += ' your threshold of ' + n.notif_value + n.notif_unit + ".\n";
          let newmsg = {
            subject: 'CoachProxy ALERT for ' + n.notif_type,
            payload: message,
          }
          messages.push(newmsg);
        }
        break;
      case 'triggered':
        if (!outofrange) {
          status = 'recovering';
          n.recover_time = Date.now();
        } else if (Date.now() - n.trigger_time > trigger_timeout) {
          status = 'cleared';
        }
        break;
      case 'recovering':
        if (outofrange) {
          status = 'triggered';
          n.trigger_time - Date.now();
        } else if (Date.now() - n.recover_time > recover_timeout) {
          status = 'cleared';
        }
        break;
      default:
        break;
    }

    n.notif_status = status;
  }
}

return messages;
