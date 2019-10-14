How It Works
============

Many systems in Tiffin motorhomes communicate over a [CAN
bus](https://en.wikipedia.org/wiki/CAN_bus) network, using the [RV-C
communication protocol](https://en.wikipedia.org/wiki/RV-C).
Understanding the RV-C protocol is essential for communicating with
Tiffin subsystems. Download the complete [RV-C
specification](http://www.rv-c.com/?q=node/75) for details on the
RV-C commands and their parameters.

Hardware
--------

To build an RV-C interface device like CoachProxy, a Raspberry Pi (RPi)
3B is the recommended hardware choice. An RPi 3B+ may work, but has not
been tested. An RPi 4 uses additional power and is not recommended, nor
has it been tested.

To connect and communicate with the RV-C network in the motorhome, a CAN
Bus board must be added to the RPi. A board with built-in SMPS (switch
mode power supply) will enable the RPi to be powered by the CAN Bus
network, eliminating the need for a separate power supply. Searching the
web for `PiCAN2 SMPS` should yield suitable results.

For connection to a Tiffin motorhome, a 4-conductor CAN Bus cable will
need to be connected to the PiCAN2 board, and a
[3M Mini-Clamp Plug](https://www.digikey.com/product-detail/en/3m/37104-2165-000%20FL%20100/3M155844-ND/1238214)
connector added to the other end of the cable. This connector can plug
into the Tiffin network panel, usually in the bedroom, bathroom, or
closet of the RV.

3rd Party Software
------------------

The logic and user interface software used by CoachProxyOS is called
[Node-RED](https://nodered.org/), along with the [Node-RED
Dashboard](https://github.com/node-red/node-red-dashboard) extension. It
enables building a web-based user interface with connections and logic
between interface components.

The [Mosquitto](https://mosquitto.org/) message broker is used by
CoachProxyOS to pass [MQTT](http://mqtt.org/) messages and data between
various programs and components.

Integration with Alexa Echo and Echo Dot devices is provided through the
[HA-Bridge](https://github.com/bwssytems/ha-bridge) package. This
integration only works with the Echo and Echo Dot, not other
Alexa-enabled devices.

Receiving RV-C Messages from CANbus
-----------------------------------

The `rvc2mqtt.pl` script listens to all RV-C messages on the CAN Bus
network, decodes them, and publishes summary information in JSON format
to the MQTT message broker on the local host.

This script loads `rvc-spec.yml`, a machine readable version of the RV-C
specification in [YAML](https://yaml.org/spec/1.2/spec.html) format.
The file describes how to decode each byte and bit of the data stream
into keys and values.

_Note 1: There are are few RV-C DGN decoders remaining to be added to
the `rvc-spec.yml` file._

_Note 2: The RV-C spec PDF has errors and inaccuracies. Where possible,
comments have been included in the `rvc-spec.yml` to explain the
discrepencies._

_Note 3: The `rvc-spec.yml` file is versioned, so that any changes to
the mqtt output can be tracked and downstream scripts can be updated.
Please review the [decoder API version log](rvc2mqtt-api-versions.md)._

For example, the `rvc-spec.yml` file contains the following decoder
information for RV-C datagroup `1FF9C`, based on section 6.17.11 of the
RV-C specification:

```yaml
1FF9C:
  name: THERMOSTAT_AMBIENT_STATUS
  parameters:
    - byte: 0
      name: instance
      type: uint8
    - byte: 1-2
      name: ambient temp
      type: uint16
      unit: Deg C
```

When the `rvc2mqtt.pl` script detects a `1FF9C` data packet on the canbus,
it uses the above YAML to decode the packet and publish the following JSON
to the MQTT bus:

```json
{
  "dgn":"1FF9C",
  "name":"THERMOSTAT_AMBIENT_STATUS",
  "instance":1,
  "ambient temp":27.7,
  "data":"0197250000000000",
  "timestamp":"1550782537.136680"
}
```

Since other tools use the mqtt outputs of the script, the decoder spec
is versioned so that any changes to the output can be tracked and
downstream scripts can be updated.

`rvc2mqtt.pl` publishes (and retains) the current API version on mqtt
topic `RVC/API_VERSION`.

Sending RV-C Messages to CANbus
-----------------------------------

There are several scripts which send messags to the CAN Bus network, to
control lights, fans, etc. A few examples are described below:

### dc_dimmer.pl

Sends a `DC_DIMMER_COMMAND_2` message (`1FEDB`) to the CAN bus. This is
typically used to control lights, but can also be used to turn other
items on and off, such as a water pump or fan.

### dc_dimmer_pair.pl

Sends a combination of `DC_DIMMER_COMMAND_2` messages (`1FEDB`) to
control various devices which have two instances associated with them.
Over time, this script can replace `ceiling_fan.pl`, `vent_fan.pl`, and
part of `window_shade.pl`).

For example, opening and closing a ceiling vent lid on a Tiffin
motorhome requires a pair of reversing commands with a duration value.
For example, to open the galley vent lid, the following sequence is
sent:

```
Instance 27
Brightness 0
Command Off
Duration 0

Instance 26
Brightness 100%
Command On
Duration 20s
```

To close the vent lid, the following sequence is sent (note the
instances are reversed):

```
Instance 26
Brightness 0
Command Off
Duration 0

Instance 27
Brightness 100%
Command On
Duration 20s
```

### ceiling_fan.pl

Sends a combination of `DC_DIMMER_COMMAND_2` messages (`1FEDB`) to
control the bedroom ceiling fan.

### vent_fan.pl

Sends `DC_DIMMER_COMMAND_2` messages (`1FEDB`) to the CAN bus to control
the ceiling vent lids and fans in Tiffin motorhomes.

Turning fans on and off is handled via a single command, just like
turning a light on or off.

Opening and closing a vent lid requires a pair of reversing commands
with a duration value.

### window_shade.pl

Sends either `WINDOW_SHADE_COMMAND` messages (`1FEDF`) or
`DC_DIMMER_COMMAND_2` messages (`1FEDB`) to control both window shades
and outdoor awnings. In Tiffin motorhomes, most window shades and
awnings are controlled via the `WINDOW_SHADE_COMMAND`, but some some
shades use the `DC_DIMMER_COMMAND_2` instead.

To simplify the interface, a single meta ID is used in the script to
control each shade set or awning, abstracting away the need to know
which RV-C command to send. For example, ID 1 sends
`DC_DIMMER_COMMAND_2` messages to dimmers 77 through 80 to control the
up and down motion of the day and night shades next to the passenger
side dinette.

In addition, different model years use slightly different versions of
the RV-C commands, so the model year must be supplied on the command
line.

Example usage: `window_shade.pl 2018 night up 17` will generate an RV-C
command to roll up the entry door night shade.

User Interface
--------------

The `flows_rvcproxy.json` file inside the `node-red` directory contains
a set of Node-RED flows for creating a dashboard to control lights,
vents, fans, thermostats, and more. Please see the [documentation for
Node-RED](https://nodered.org/docs/) for instructions to load and work
with this file.

The flows utilize several Node-RED modules which must be installed
first. At the very least, the following are required:

* node-red-dashboard
* node-red-contrib-file-function-ext

The `file-function-ext` module loads javascript code snippets from
files, rather than the traditional approach of embedding the javascript
code inside the Node-RED flows file. Several sample javascript files
have been added to this repository.

![Node-RED Flows](images/flows-1.jpg)
