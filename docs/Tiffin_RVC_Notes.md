Thermostats
-----------

Thermostats were first added in 2018.

Thermostat differences:

* Open Road and RED use instances 0, 1, and 2 for front, middle, and
  rear roof unit zones.
* Phaeton, Bus, and Zephyr use instances 2, 3, and 4 for front, middle,
  and rear roof units. Everything is two higher because these coaches
  reserve instances 0 and 1 for the front and rear heated floors.

Instance numbers apply to `THERMOSTAT_AMBIENT_STATUS`, `THERMOSTAT_STATUS`,
`THERMOSTAT_COMMAND`, and related commands.

Furnace differences:

* Open Road and Allegro RED use instances 3 and 4 for front and rear furnace zones.
* Phaeton, Bus, and Zephyr use instances 5 and 6 for front and rear furnace zones.

First furnace instance is always 3 plus first roof unit instance.

Furnaces do not report `THERMOSTAT_AMBIENT_STATUS`, so the instances only
apply to `THERMOSTAT_STATUS` and `THERMOSTAT_COMMAND`.

Thermistors:

* Phaeton, Bus, and Zephyr use instances 6 and 7 for
  `THERMOSTAT_AMBIENT_STATUS` readings from two exterior thermistors: wet
  bay, and generator bay.

Shorter coaches may only have two HVAC zones. In these cases, the middle
zone is the missing zone.

Allegro REDs with three zones do not have a heat pump in the center
zone, just an air conditioner.


Vent lids
---------

Vent lids use reversing loads, and require two commands to make them go
up or down. For example, in the 2018 Phaeton 40 IH, the rear vent lid
uses dimmer loads 33 and 34. To open the lid:

`DC_DIMMER_COMMAND_2` is sent to load ID 34 with values:

* Brightness: 0
* Command:    Off (Delay)
* Duration:   0

`DC_DMMER_COMMAND_2` is then also sent to load ID 33 with values:

* Brightness: 100
* Command:    On (Duration)
* Duration:   20 seconds

To close the lid, ID 33 is set to "0, Off, 0" and 34 is set to "100, On, 20".

For coaches before the 2018 Phaeton, a separate command must also be
sent to update the indicator light on the Spyder keypad.

`GENERIC_INDICATOR_COMMAND` is sent to the indicator ID with one of these
sets of parameters:

* Function: 03 - LED 1 off, LED 2 on
* Function: 02 - LED 1 on,  LED 2 off


Panel Lights
------------

Panel lights are turned on, off, and dimmed as follows:

`GENERIC_INDICATOR_COMMAND` is sent with values:

* Group:      (panel ID)
* Brightness: (desired brightness)
* Function:   00 (set brightness for LED 1 and LED 2)
