Telemosaic [telemosaic]
=======================

A Minetest mod for user-generated teleportation pads.

Version: 0.5.0

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

Beacons are created with 2 diamonds, 3 obsidian blocks, and a wooden
door: first row diamond, door, diamond; second row the obsidian blocks.

Right-clicking a beacon with a default mese crystal fragment remembers
the position in the fragment, which turns into a telemosaic key.
Right-clicking a second beacon with the key sets up a teleportation
route from the second beacon to the first beacon. To set up a return
path, right-click the second beacon with the fragment, and the first
beacon with the resulting key again.

The beacons do not need to be strictly paired this way: rings or
star-shaped networks are also possible. Each beacon has only a
single destination, but can itself be the destination of several
others.

Beacons will check that their destination is sane: the destination
still needs to be a beacon, and the two nodes above it should be
clear for walking / standing in. If your Minetest version supports
it, the beacon will emerge the area prior to checking and teleporting.
Emerging is merely a convenience, though.

Beacons have a maximum range of 20 nodes. If the destination is
too far away, the beacon will turn red and will not function.
To extend the range for a beacon, place "extenders" next to it,
within a 7x7 horizontal square centered on the beacon.

Extenders come in three tiers: tier 1 extends all affected beacons
by 5 nodes, tier 2 by 20 nodes, and tier 3 by 80 nodes. Placing
or digging extenders will update affected beacons.

Tier 1 extenders are crafted by placing an obsidian block, a wooden
door, and another obsidian block in a horizontal row. Tier 2 extenders
are crafted with an obsidian block in the middle, surrounded by a cross
of four tier 1 extenders. Tier 3 extenders are crafted with an obsidian
block surrounded by four tier 2 extenders.

Extenders can be colored with any of the dyes found in the dye mod.
Colored extenders work just like regular extenders, both for
teleporting and for recipes. To "uncolor" an extender, dye it grey.

Future plans
------------

* Particle and sound effects
* Protected beacons (will not teleport if protected)

Dependencies
------------
* default
* doors
* dye (optional)

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
