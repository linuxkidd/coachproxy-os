Hardware Build
==============

To build an RV-C interface device like CoachProxy, a Raspberry Pi (RPi)
3B is the recommended hardware choice. An RPi 3B+ may work, but has not
been tested. An RPi 4 uses additional power and is not recommended, nor
has it been tested.

To connect and communicate with the RV-C network in the motorhome, a CAN
Bus board must be added to the RPi. A board with built-in SMPS (switch
mode power supply) will enable the RPi to be powered by the CAN Bus
network, eliminating the need for a separate power supply. Searching the
web for `PiCAN2 SMPS` should yield suitable results. A board commonly
used for this is available at https://copperhilltech.com/pican2-can-interface-for-raspberry-pi-with-smps/

For connection to a Tiffin motorhome, a 4-conductor CAN Bus cable will
need to be connected to the PiCAN2 board, and a
[3M Mini-Clamp Plug](https://www.digikey.com/product-detail/en/3m/37104-2165-000%20FL%20100/3M155844-ND/1238214)
connector added to the other end of the cable. This connector can plug
into the Tiffin network panel, usually in the bedroom, bathroom, or
closet of the RV.

