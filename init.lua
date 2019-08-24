--[[

Telemosaic [telemosaic]
=======================

A mod which provides player-placed teleport pads

Copyright (C) 2015 Ben Deutsch <ben@bendeutsch.de>

License
-------

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301
USA

]]

telemosaic = {
    -- configuration
    config = {
        -- keep emerge_delay lower than teleport_delay!
        emerge_delay = 0.5, -- seconds
        teleport_delay = tonumber(minetest.settings:get("telemosaic_teleport_delay")) or 2.0, -- seconds
        beacon_range = tonumber(minetest.settings:get("telemosaic_beacon_range")) or 20.0, -- max teleport distance
        extender_ranges = {
            -- note: not adding beacons here, since they don't extend
            -- also: base name of colored versions
            ['telemosaic:extender_one'] = tonumber(minetest.settings:get("telemosaic_extender_one_range")) or 5.0,
            ['telemosaic:extender_two'] = tonumber(minetest.settings:get("telemosaic_extender_two_range")) or 20.0,
            ['telemosaic:extender_three'] = tonumber(minetest.settings:get("telemosaic_extender_three_range")) or 80.0,
        },
		right_click_teleport = minetest.settings:get_bool("telemosaic_right_click_teleport") or false,
    },

    players = {
        --[[
        name = {
            last_pos = '-10:5:3',
            time_in_pos = 0.0,
            allow_teleport = true,
            started_emerge = false,
        }
        ]]
    },

}

local modpath = minetest.get_modpath(minetest.get_current_modname())

dofile(modpath.."/teleport.lua")
dofile(modpath.."/crafts.lua")
dofile(modpath.."/abm.lua")
