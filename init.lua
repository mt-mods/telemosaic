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
        teleport_delay = 2.0, -- seconds
        beacon_range = 20.0, -- max teleport distance
        extender_ranges = {
            -- note: not adding beacons here, since they don't extend
            ['telemosaic:extender_one'] = 5.0,
            ['telemosaic:extender_two'] = 20.0,
            ['telemosaic:extender_three'] = 80.0,
        },
    },

    players = {
        --[[
        name = {
            last_pos = '-10:5:3',
            time_in_pos = 0.0,
            allow_teleport = true,
        }
        ]]
    },

}

local M = telemosaic
local C = M.config

local function hash_pos(pos)
    return math.floor(pos.x + 0.5) .. ':' ..
           math.floor(pos.y + 0.5) .. ':' ..
           math.floor(pos.z + 0.5)
end
local function unhash_pos(hash)
    local pos = {}
    local list = string.split(hash, ':')
    pos.x = tonumber(list[1])
    pos.y = tonumber(list[2])
    pos.z = tonumber(list[3])
    return pos
end

local function count_extenders(pos)
    local extended = 0.0
    for z=-3,3 do
        for x=-3,3 do
            local node = minetest.get_node({ x=pos.x+x, y=pos.y, z=pos.z+z})
            extended = extended + ( C.extender_ranges[node.name] or 0.0 )
        end
    end
    --print("Total extended: " .. extended)
    return extended
end

local function beacon_rightclick(pos, node, player, itemstack, pointed_thing)
    local name = itemstack:get_name()
    --print("Clicked by a " ..name)
    if name == 'default:mese_crystal_fragment' and itemstack:get_count() == 1 then
        --print("Clicked by a single key")
        itemstack = ItemStack({
            name = "telemosaic:key",
            count = 1,
            wear = 0,
            metadata = hash_pos(pointed_thing.under),
        })
    elseif name == 'telemosaic:key' then
        local posstring = itemstack:get_metadata()
        local thispos = hash_pos(pointed_thing.under)
        --print("Key with metadata " .. posstring)
        if posstring ~= thispos then
            local dest_pos = unhash_pos(posstring)
            local extended = count_extenders(pointed_thing.under)
            if vector.distance(dest_pos, pointed_thing.under) <= C.beacon_range + extended then
                minetest.swap_node(pointed_thing.under, { name = "telemosaic:beacon" })
            else
                minetest.swap_node(pointed_thing.under, { name = "telemosaic:beacon_err" })
            end

            -- set the destination anyway, it just won't work as
            -- long as the beacon is in err state
            local meta = minetest.get_meta(pointed_thing.under)
            meta:set_string('telemosaic:dest', posstring)
            --print ("set to " .. meta:get_string('telemosaic:dest'))
            itemstack = ItemStack({
                name = "default:mese_crystal_fragment",
                count = 1, wear = 0,
            })
        end
    else
        -- normal place-item thing
        if itemstack:get_definition().type == "node" then
            return core.item_place_node(itemstack, player, pointed_thing)
        end
    end
    return itemstack
end

local function extender_place(placepos, placer, itemstack, pointed_thing)
    -- go over all possible *err* beacons, and update them
    for z=-3,3 do
        for x=-3,3 do
            local pos = { x=placepos.x+x, y=placepos.y, z=placepos.z+z }
            local node = minetest.get_node(pos)
            if node ~= nil and node.name == 'telemosaic:beacon_err' then
                -- candidate!
                local dest_hash = minetest.get_meta(pos):get_string('telemosaic:dest')
                if dest_hash ~= nil and dest_hash ~= '' then
                    local dest = unhash_pos(dest_hash)
                    local extended = count_extenders(pos)
                    local dist = vector.distance(pos, dest)
                    if dist <= C.beacon_range + extended then
                        -- upgrade :-)
                        minetest.swap_node(pos, { name = "telemosaic:beacon" })
                    end
                end
            end
        end
    end
end

local function extender_dig(digpos, oldnode, oldmetadata, digger)
    -- go over all possible *actual* beacons, and update them
    for z=-3,3 do
        for x=-3,3 do
            local pos = { x=digpos.x+x, y=digpos.y, z=digpos.z+z }
            local node = minetest.get_node(pos)
            if node ~= nil and node.name == 'telemosaic:beacon' then
                -- candidate!
                local dest_hash = minetest.get_meta(pos):get_string('telemosaic:dest')
                if dest_hash ~= nil and dest_hash ~= '' then
                    local dest = unhash_pos(dest_hash)
                    local extended = count_extenders(pos)
                    local dist = vector.distance(pos, dest)
                    if dist > C.beacon_range + extended then
                        -- downgrade :-(
                        minetest.swap_node(pos, { name = "telemosaic:beacon_err" })
                    end
                end
            end
        end
    end
end

minetest.register_node('telemosaic:beacon_off', {
    description = 'Telemosaic beacon',
    tiles = {
        'telemosaic_beacon_off.png',
        'telemosaic_beacon_side.png',
        'telemosaic_beacon_side.png',
        'telemosaic_beacon_side.png',
        'telemosaic_beacon_side.png',
        'telemosaic_beacon_side.png',
    },
    paramtype = 'light',
    groups = { cracky = 2 },
    on_rightclick = beacon_rightclick,
})
minetest.register_node('telemosaic:beacon', {
    description = 'Telemosaic beacon (on)',
    tiles = {
        'telemosaic_beacon_top.png',
        'telemosaic_beacon_side.png',
        'telemosaic_beacon_side.png',
        'telemosaic_beacon_side.png',
        'telemosaic_beacon_side.png',
        'telemosaic_beacon_side.png',
    },
    paramtype = 'light',
    groups = { cracky = 2, not_in_creative_inventory = 1 },
    drop = 'telemosaic:beacon_off',
    on_rightclick = beacon_rightclick,
})
minetest.register_node('telemosaic:beacon_err', {
    description = 'Telemosaic beacon (err)',
    tiles = {
        'telemosaic_beacon_err.png',
        'telemosaic_beacon_side.png',
        'telemosaic_beacon_side.png',
        'telemosaic_beacon_side.png',
        'telemosaic_beacon_side.png',
        'telemosaic_beacon_side.png',
    },
    paramtype = 'light',
    groups = { cracky = 2, not_in_creative_inventory = 1 },
    drop = 'telemosaic:beacon_off',
    on_rightclick = beacon_rightclick,
})

minetest.register_node('telemosaic:beacon_off', {
    description = 'Telemosaic beacon',
    tiles = {
        'telemosaic_beacon_off.png',
        'telemosaic_beacon_side.png',
        'telemosaic_beacon_side.png',
        'telemosaic_beacon_side.png',
        'telemosaic_beacon_side.png',
        'telemosaic_beacon_side.png',
    },
    paramtype = 'light',
    groups = { cracky = 2 },
    on_rightclick = beacon_rightclick,
})


minetest.register_tool('telemosaic:key', {
    description = 'Telemosaic key',
    inventory_image = 'telemosaic_key.png',
    stack_max = 1,
    groups = { not_in_creative_inventory = 1 },
})

minetest.register_node('telemosaic:extender_one', {
    description = 'Telemosaic extender, tier 1',
    tiles = {
        'telemosaic_extender_one.png',
    },
    paramtype = 'light',
    groups = { cracky = 2 },
    after_place_node = extender_place,
    after_dig_node   = extender_dig,
})
minetest.register_node('telemosaic:extender_two', {
    description = 'Telemosaic extender, tier 2',
    tiles = {
        'telemosaic_extender_two.png',
    },
    paramtype = 'light',
    groups = { cracky = 2 },
    after_place_node = extender_place,
    after_dig_node   = extender_dig,
})
minetest.register_node('telemosaic:extender_three', {
    description = 'Telemosaic extender, tier 3',
    tiles = {
        'telemosaic_extender_three.png',
    },
    paramtype = 'light',
    groups = { cracky = 2 },
    after_place_node = extender_place,
    after_dig_node   = extender_dig,
})

minetest.register_on_joinplayer(function(player)
    local name = player:get_player_name()
    if not M.players[name] then
        local pos = player:getpos()
        local pos_hash = hash_pos(pos)
        M.players[name] = {
            last_pos = pos_hash,
            time_in_pos = 0.0,
            allow_teleport = false, -- no teleport after join
        }
    end
end)

minetest.register_globalstep(function(dtime)
    for _,player in ipairs(minetest.get_connected_players()) do
        local name = player:get_player_name()
        local pl = M.players[name]
        local pos = player:getpos()
        local pos_hash = hash_pos(pos)
        -- from now on, pos is slightly *under* the player
        pos.y = pos.y - 0.01
        local stand_node = minetest.get_node(pos)
        --print ("At position " .. pos_hash .. " standing on a " .. stand_node.name)
        if pos_hash ~= pl.last_pos then
            --print("Moved to " .. pos_hash)
            pl.last_pos = pos_hash
            pl.time_in_pos = 0.0
            pl.allow_teleport = true
        elseif pl.allow_teleport and stand_node.name == 'telemosaic:beacon' then
            pl.time_in_pos = pl.time_in_pos + dtime
            if pl.time_in_pos > C.teleport_delay then
                local dest_hash = minetest.get_meta(pos):get_string('telemosaic:dest')
                if dest_hash ~= nil and dest_hash ~= '' then
                    --print("Ping to " .. dest_hash)
                    local dest = unhash_pos(dest_hash)
                    dest.y = dest.y + 0.5
                    local extended = count_extenders(pos)
                    -- check for range before teleport (with leeway)
                    local dist = vector.distance(pos, dest)
                    --print("Dist :" .. (dist-0.5) .. " to " .. (C.beacon_range + extended))
                    if dist - 0.5 <= C.beacon_range + extended then
                        player:setpos(dest)
                        pl.last_pos = hash_pos(dest)
                    end
                    pl.allow_teleport = false -- need to move first, regardless
                end
            end
        end
    end
end)

