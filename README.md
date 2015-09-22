Telemosaic [telemosaic]
=======================

A Minetest mod for user-generated teleportation pads.

Version: 0.1.0

License:
  Code: LGPL 2.1 (see included LICENSE file)
  Textures: CC-BY-SA (see http://creativecommons.org/licenses/by-sa/4.0/)

Report bugs or request help on the forum topic.

Description
-----------

This is a mod for MineTest. It provides teleportation pads, called
"beacons". Unlike other teleportation mods, no menus or GUIs are used;
you set the destination with a simple "key" item. There is no
tooltip for the destination either, so signs are recommended.

Another difference is the limited default range of the beacons.
To increase the range, you need to place "extenders" around the beacon.
The extenders come in different colors, allowing the extenders to
form a pretty pattern; hence the name "telemosaic".

Current behavior
----------------

Beacons can be found in the creative inventory. Right-clicking a
beacon with a default mese crystal fragment remembers the position
in the fragment, which turns into a full mese crystal. Right-clicking
a second beacon with the full crystal sets up a teleportation route
from the second beacon to the first beacon. To set up a return
path, right-click the second beacon with the fragment, and the
first beacon with the full crystal again.

The beacons do not need to be strictly paired this way: rings or
star-shaped networks are also possible. Each beacon has only a
single destination, but can itself be the destination of several
others.

Future plans
------------

* Different textures for unset and set beacons
* Limited range for beacons
* A separate key item, or at least for the "charged" version
* Extenders
* Crafting recipes for beacons and extenders
* Particle and sound effects
* Several tiers of extenders
* Dyeing extenders

Dependencies
------------
* default

Installation
------------

Unzip the archive, rename the folder to to `bewarethedark` and
place it in minetest/mods/

(  Linux: If you have a linux system-wide installation place
    it in ~/.minetest/mods/.  )

(  If you only want this to be used in a single world, place
    the folder in worldmods/ in your worlddirectory.  )

For further information or help see:
http://wiki.minetest.com/wiki/Installing_Mods
