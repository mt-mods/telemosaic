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
        teleport_delay = 2.0, -- seconds
        beacon_range = 20.0, -- max teleport distance
        extender_ranges = {
            -- note: not adding beacons here, since they don't extend
            -- also: base name of colored versions
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
            started_emerge = false,
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
            local name = node.name
            -- trim color off the back
            name = string.gsub(name, '^(telemosaic:extender_%a+)_%a+', '%1')
            extended = extended + ( C.extender_ranges[name] or 0.0 )
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
        if posstring ~= thispos and not minetest.is_protected(pointed_thing.under, player:get_player_name()) then
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
                    else
                        local count = math.ceil(dist - (C.beacon_range + extended))
                        minetest.chat_send_player(placer:get_player_name(), "You still need to add extensions for "..count.." nodes" )
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

local function check_teleport_dest(dest)
    -- check the destination node for beacons, and the two nodes
    -- above for "walkthrough"
    -- "ignore" is ok, we could not emerge in time then.
    local dest_bot = minetest.get_node({ x = dest.x, y = dest.y  , z = dest.z })
    local dest_mid = minetest.get_node({ x = dest.x, y = dest.y+1, z = dest.z })
    local dest_top = minetest.get_node({ x = dest.x, y = dest.y+2, z = dest.z })
    --print ("Looking at " .. dest_bot.name .. ", " .. dest_mid.name .. ", " .. dest_top.name)
    local dest_ok  = true
    if dest_bot.name ~= 'ignore' and not string.match(dest_bot.name, '^telemosaic:beacon') then
        dest_ok = false
        --print("Bottom is not beacon")
    end
    if dest_mid.name ~= 'ignore' and dest_mid.name ~= 'air' then
        local def = minetest.registered_nodes[dest_mid.name]
        if def and def.walkable then
            dest_ok = false
            --print("Mid is walkable")
        end
    end
    if dest_top.name ~= 'ignore' and dest_top.name ~= 'air' then
        local def = minetest.registered_nodes[dest_top.name]
        if def and def.walkable then
            dest_ok = false
            --print("Top is walkable")
        end
    end
    return dest_ok
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

-- extenders come in three strengths, and many colors

local strengths = {
    -- index starts at 1
    'one',
    'two',
    'three',
}
local colors = {
    -- TODO: localisation
    -- default: { name= 'grey', value= '#ffffff00'},
    { name= 'white', value= '#ffffff80'},
    { name= 'dark_grey', value= '#000000c0'},
    { name= 'black', value= '#00000080'},
    { name= 'violet', value= '#40008080'},
    { name= 'blue', value= '#0000ff80'},
    { name= 'cyan', value= '#00ffff80'},
    { name= 'dark_green', value= '#00800080'},
    { name= 'green', value= '#00ff0080'},
    { name= 'yellow', value= '#ffff0080'},
    { name= 'brown', value= '#80400080'},
    { name= 'orange', value= '#ff800080'},
    { name= 'red', value= '#ff000080'},
    { name= 'magenta', value= '#ff00ff80'},
    { name= 'pink', value= '#ff808080'},
}

for num, strength in ipairs(strengths) do
    minetest.register_node(string.format('telemosaic:extender_%s', strength), {
        description = string.format('Telemosaic extender, tier %d', num),
        tiles = {
            string.format('telemosaic_extender_%s.png', strength)
        },
        paramtype = 'light',
        groups = { cracky = 2, [string.format('telemosaic_extender_%s', strength)] = 1 },
        after_place_node = extender_place,
        after_dig_node   = extender_dig,
    })
    -- colored versions, not in creative inventory, if dyes available
    if minetest.get_modpath('dye') then
        for _,c in ipairs(colors) do
            minetest.register_node(string.format('telemosaic:extender_%s_%s', strength, c.name), {
                description = string.format('Telemosaic extender, tier %d (%s)', num, c.name),
                tiles = {
                    string.format('telemosaic_extender_%s.png^[colorize:%s', strength, c.value),
                },
                paramtype = 'light',
                groups = { cracky = 2, [string.format('telemosaic_extender_%s', strength)] = 1, not_in_creative_inventory = 1 },
                after_place_node = extender_place,
                after_dig_node   = extender_dig,
            })
        end
    end
end

minetest.register_craft({
    output = 'telemosaic:beacon_off',
    recipe = {
        {'default:diamond', 'doors:door_wood', 'default:diamond'},
        {'default:obsidian','default:obsidian','default:obsidian'}
    }
})
minetest.register_craft({
    output = 'telemosaic:extender_one',
    recipe = {
        {'default:obsidian','doors:door_wood','default:obsidian'}
    }
})
minetest.register_craft({
    output = 'telemosaic:extender_two',
    recipe = {
        {'', 'group:telemosaic_extender_one',''},
        {'group:telemosaic_extender_one','default:obsidian','group:telemosaic_extender_one'},
        {'', 'group:telemosaic_extender_one',''}
    }
})
minetest.register_craft({
    output = 'telemosaic:extender_three',
    recipe = {
        {'', 'group:telemosaic_extender_two',''},
        {'group:telemosaic_extender_two','default:obsidian','group:telemosaic_extender_two'},
        {'', 'group:telemosaic_extender_two',''}
    }
})

-- coloring recipes
if minetest.get_modpath('dye') then
    for num, strength in ipairs(strengths) do
        -- uncolor
        minetest.register_craft({
            type = "shapeless",
            output = string.format('telemosaic:extender_%s', strength),
            recipe = { string.format('group:telemosaic_extender_%s', strength), 'dye:grey' },
        })
        -- color with dye
        for _,c in ipairs(colors) do
            minetest.register_craft({
                type = "shapeless",
                output = string.format('telemosaic:extender_%s_%s', strength, c.name),
                recipe = { string.format('group:telemosaic_extender_%s', strength), string.format('dye:%s', c.name) },
            })
        end
    end
end

-- how to recycle a key
minetest.register_craft({
    type = 'shapeless',
    recipe = {'telemosaic:key'},
    output = 'default:mese_crystal_fragment'
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
            started_emerge = false, -- had not emerged destination yet
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
            pl.started_emerge = false
        elseif pl.allow_teleport and stand_node.name == 'telemosaic:beacon' then
            pl.time_in_pos = pl.time_in_pos + dtime

            if pl.time_in_pos > C.emerge_delay and not pl.started_emerge then
                pl.started_emerge = true
                if minetest.emerge_area then
                    local dest_hash = minetest.get_meta(pos):get_string('telemosaic:dest')
                    if dest_hash ~= nil and dest_hash ~= '' then
                        local dest = unhash_pos(dest_hash)
                        local pos_top = { x = dest.x, y = dest.y - 2, z = dest.z }
                        -- try to emerge the area
                        --print("Emerging " .. hash_pos(dest) .. " to " .. hash_pos(pos_top))
                        minetest.emerge_area(dest, pos_top)
                    end
                end
            end

            if pl.time_in_pos > C.teleport_delay then
                local dest_hash = minetest.get_meta(pos):get_string('telemosaic:dest')
                if dest_hash ~= nil and dest_hash ~= '' then
                    local dest = unhash_pos(dest_hash)

                    -- test destination nodes
                    local dest_ok = check_teleport_dest(dest)

                    --print("Ping to " .. dest_hash)
                    local extended = count_extenders(pos)
                    -- check for range before teleport (with leeway)
                    local dist = vector.distance(pos, dest)
                    --print("Dist :" .. (dist-0.5) .. " to " .. (C.beacon_range + extended))

                    if dest_ok and dist - 0.5 <= C.beacon_range + extended then
                        dest.y = dest.y + 0.5
                        player:setpos(dest)
                        pl.last_pos = hash_pos(dest)
                    else
                        -- beacon is in error, one way or another.
                        -- but don't swap it out - we won't get it back otherwise!
                    end
                    pl.allow_teleport = false -- need to move first, regardless
                end
            end

        end
    end
end)

