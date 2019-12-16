CoachProxyOS
============

CoachProxy**OS** is the **O**pen **S**ource version of the software behind
[CoachProxy](https://coachproxy.com), a device for interfacing
with, monitoring, and managing Tiffin motorhomes.

This repository provides a set of
[Ansible](https://docs.ansible.com/ansible/latest/index.html) playbooks
to create a functioning CoachProxyOS system image from a base Raspberry
Pi operating system.

Differences from the commercial CoachProxy Software
---------------------------------------------------

CoachProxyOS's [RV monitoring and control
capabilities](https://coachproxy.com/instructions/) are identical to
those of the commercial CoachProxy system. However, several changes have
been made to make it suitable for an Open Source Project. The major
changes are:

* To enable e-mail notifications, users must configure their own
  SMTP email server settings in the CoachProxyOS interface (SMTP
  server, port number, username, and password).
* To configure WiFi network information, a file must be edited on
  the boot partition of the CoachProxy operating system image by
  inserting the microSD card in a computer to edit the file.
* CoachProxy's memory card was configured with a read-only filesystem
  to prevent corruption of the SD card, for example if power was lost
  while a file was being written. This configuration been removed from
  CoachProxyOS to reduce complexity and make DIY changes easier.

Other Information
-----------------

See the [INSTALL](INSTALL.md) file for instructions on creating a
CoachProxyOS image using Ansible.

See the [HOW_IT_WORKS](HOW_IT_WORKS.md) file for information on how to
build a Raspberry Pi device that can communicate with an RV, and how the
CoachProxyOS software works.

See the [ROADMAP](ROADMAP.md) file for information on what future
changes would benefit the project.

Downloads
---------

For those not willing or able to create the CoachProxyOS software image
themselves, a fully-functioning downloadable image containing the latest
changes will periodically be uploaded to the
[Releases](https://github.com/rvc-proxy/coachproxy-os/releases) page.

Screenshots
-----------

![Interior](images/ui-interior.png)
