Roadmap
=======

CoachProxyOS is _not_ being actively developed. However, the following
is a rough outline of potential improvements that could benefit the
project:

* 2020 Tiffin support: Most of this could be accomplished by updating
  the [features.json](roles/coachproxy/files/configurator/features.json)
  file with the correct IDs for 2020 RVs. However, some more complicated
  changes will almost certainly be needed in other files as well.

* Simplify management of configuration information. Currently a sqlite3
  database is used, but data is stored in several unrelated and
  differently managed tables. A consistent method should be designed and
  all code updated. One approach may be to eliminate the sqlite3
  database entirely and use
  [Persistent Context](https://discourse.nodered.org/t/a-guide-to-understanding-persistent-context/4115).

* Write documentation for various features, such as Remote
  Access, notifications, presets, and Alexa integration.
