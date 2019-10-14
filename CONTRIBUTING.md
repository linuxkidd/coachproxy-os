# Welcome

Welcome to CoachProxyOS, the Open Source version of the CoachProxy RV control
system. CoachProxyOS is not under _active_ development, but small improvements
are still being made from time to time.

Want to help out? Great! Here's what you need to know...

## Technologies

The main technologies CoachProxyOS uses are:

* Node-RED - an event-driven node.js framework which manages most of the
  logic within CoachProxyOS.
* Node-RED Dashboard - a drag-and-drop user interface builder for Node-RED.
* Javascript - for developing the real-time logic within Node-RED.
* Perl - for back-end communication with the RV CAN bus network.
* Perl and JQ - for building the custom user interface for the selected
  RV year, model, and floor plan.
* MQTT - a message broker protocol used to pass data between various
  components of CoachProxyOS.
* Shell script - for some operating system management scripts.
* Debian Linux - the operating system CoachProxyOS runs on top of.
* NGINX - a reverse-proxy web front-end for the user interface.
* Ansible - to automate the build of the CoachProxyOS SD card images.

## Contributing to CoachProxyOS

When contributing to this repository, please first discuss the change you wish
to make via issue, email, or other method with the owner of this repository.

* Create issues for any enhancements or fixes you wish to make.
* Before creating a new issue, ensure a similar existing issue doesn't already exist.
* Keep contributions as small as possible, preferably one new feature or fix per version.

Current issues: https://github.com/rvc-proxy/coachproxy-os/issues

## License

By contributing to this project, you agree that your contributions will
be licensed under its GPL v3.0 License.
