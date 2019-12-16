Using a Pre-Built Image
=======================

For those who don't wish to create their CoachProxyOS operating system
from scratch using Ansible, a ready-to-use downloadable image of the
latest release is usually available.

Download Software Image
-----------------------

Visit the CoachProxyOS
[Releases](https://github.com/rvc-proxy/coachproxy-os/releases) page and
download the latest `.img.zip` file. The image is large (approximately
1GB).

Install Image on microSD Card
-----------------------------

Download and install the free `Etcher` program from https://etcher.io/

Insert a microSD card into your computer or USB card reader.

Run Etcher, select your downloaded CoachProxyOS_#.img.zip file, select your SD card, and click `Flash`.

Configure WiFi
--------------

After the image has been written, you must edit one file on the `boot`
partition of the microSD card to configure your WiFi network
information.

_Note: Etcher may have ejected the `boot` partition when it finished writing
the image. If so, just remove the microSD card and re-insert it into the
computer._

Follow the instructions at [Setting up a RPi
Headless](https://www.raspberrypi.org/documentation/configuration/wireless/headless.md)
to create the WiFi configuration file for your home network's WiFi SSID
and password.

The instructions will need you to locate the microSD card's `boot`
partition mounted on your computer and create a new file there called
`wpa_supplicant.conf`. Here is an example of what that file might look
like:

~~~
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1
country=US

network={
 ssid="MyWiFiNetworkName"
 psk="mywifipassword"
}
~~~

When finished creating the WiFi configuration file, eject the `boot`
partition and remove the microSD card.

Insert microSD Card into Device
-------------------------------

When holding the Raspberry Pi upside down, the label of the microSD card will
be toward you, and the metal pins toward the computer's board.

You're now ready to connect the device to your RV's network. After the
device starts up, you'll need to determine what network IP address your
router assigned to it, and enter that address into any web browser on
the same WiFi network.
