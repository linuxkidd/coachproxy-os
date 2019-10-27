Roadmap
=======

CoachProxyOS is _not_ being actively developed. However, the following
is a rough outline of potential improvements that could benefit the
project:

* Re-enable e-mail notifications. These currently do not work because
  they depended on using the CoachProxy.com server as a mail relay, and
  use of that server is not available for the Open Source version of
  CoachProxyOS. Alternate notification methods, such as PushOver, should
  also be explored.

* 2020 Tiffin support: Most of this could be accomplished by updating
  the `[features.json](roles/coachproxy/files/configurator/features.json)`
  file with the correct IDs for 2020 RVs. However, some more complicated
  changes will almost certainly be needed in other files as well.

* Simplify management of configuration information. Currently a sqlite3
  database is used, but data is stored in several unrelated and
  differently managed tables. A consistent method should be designed and
  all code updated. One approach may be to eliminate the sqlite3
  database entirely and use the new
  [Persistent Context](https://discourse.nodered.org/t/a-guide-to-understanding-persistent-context/4115) feature
  of Node-RED.

* Write documentation for various non-trivial components, such as Remote
  Access, notifications, presets, and Alexa integration.
