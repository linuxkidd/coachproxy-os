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

CoachProxyOS's RV monitoring and control capabilities are [identical to
those of the commercial CoachProxy
system](https://coachproxy.com/instructions/). However, several changes
have been made to make it suitable for an Open Source Project. The major
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

Documentation
-------------

[Build_Device](docs/Build_Device.md): instructions for assembling a
CoachProxyOS device from a Raspberry Pi computer.

[Build_Image](docs/Build_Image.md): instructions for creating a
CoachProxyOS image from source using Ansible.

[Download_Image](docs/Download_Image.md): instructions for downloading
a pre-built image and installing it on a CoachProxyOS device.

[Software_Overview](docs/Software_Overview.md): information on how the device
and software communicates with an RV, and how the CoachProxyOS software
works.

[Roadmap](docs/Roadmap.md): information on what future changes would benefit
the project.

Screenshots
-----------

![Interior](images/ui-interior.png)
