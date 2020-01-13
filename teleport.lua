local C = telemosaic.config

local recent_teleports = {}

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

-- returns true if the beacon is in an error state (protected or not)
local function is_err_beacon(pos)
	local node = minetest.get_node(pos)
	if not node then
		-- no node or name
		return false
	end
	return node.name == "telemosaic:beacon_err" or node.name == "telemosaic:beacon_err_protected"
end

-- swaps out the beacon with the new state suffix
local function swap_beacon(pos, new_state_suffix)
	local node = minetest.get_node(pos)
	if not node then
		-- no node at pos
		return
	end

	local name = node.name
	local new_node_name = "telemosaic:beacon" .. new_state_suffix

	if string.match(name, "_protected") then
		-- protected beacon
		new_node_name = new_node_name .. "_protected"
	end

	minetest.swap_node(pos, { name = new_node_name })
end


local function extender_place(placepos, placer, itemstack, pointed_thing)
    -- go over all possible *err* beacons, and update them
    for z=-3,3 do
        for x=-3,3 do
            local pos = { x=placepos.x+x, y=placepos.y, z=placepos.z+z }
            if is_err_beacon(pos) then
                -- candidate!
                local dest_hash = minetest.get_meta(pos):get_string('telemosaic:dest')

                if dest_hash ~= nil and dest_hash ~= '' then
                    local dest = unhash_pos(dest_hash)
                    local extended = count_extenders(pos)
                    local dist = vector.distance(pos, dest)

                    if dist <= C.beacon_range + extended then
                        -- upgrade :-)
			swap_beacon(pos, "")

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
						swap_beacon(pos, "_err")
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

local function is_protected_beacon(pos, player)
	if minetest.get_node(pos).name == 'telemosaic:beacon_protected' then
		-- check protection on protected telemosaic
		if minetest.is_protected(pos, player:get_player_name()) then
			-- protected telemosaic
			return true
		end
	end
	-- not a protected telemosaic
	return false
end

-- teleports the player with given telemosaic pos
function do_teleport(pos, player)
	
	-- prevent teleport spamming
	local player_name = player:get_player_name()
	if recent_teleports[player_name] then
		return
	end

	if is_err_beacon(pos) then
		return
	end

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

	if dest_ok and dist - 0.5 <= C.beacon_range + extended and telemosaic.travel_allowed(player, pos, dest) then
		dest.y = dest.y + 0.5

		minetest.sound_play( {name="telemosaic_set", gain=1}, {pos=pos, max_hear_distance=30})
		minetest.add_particlespawner({
			amount = 100,
			time = 0.25,
			minpos = {x=pos.x, y=pos.y+0.3, z=pos.z},
			maxpos = {x=pos.x, y=pos.y+2, z=pos.z},
			minvel = {x = 1,  y = -6,  z = 1},
			maxvel = {x = -1, y = -1, z = -1},
			minacc = {x = 0, y = -2, z = 0},
			maxacc = {x = 0, y = -6, z = 0},
			minexptime = 0.1,
			maxexptime = 1,
			minsize = 0.5,
			maxsize = 1.5,
			texture = "telemosaic_particle_departure.png",
			glow = 15,
		})
		player:set_pos(dest)

		minetest.sound_play( {name="telemosaic_teleport", gain=1}, {pos=dest, max_hear_distance=30})
		minetest.add_particlespawner({
			amount = 100,
			time = 0.25,
			minpos = {x=dest.x, y=dest.y+0.3, z=dest.z},
			maxpos = {x=dest.x, y=dest.y+2, z=dest.z},
			minvel = {x = -1, y = 1, z = -1},
			maxvel = {x = 1,  y = 6,  z = 1},
			minacc = {x = 0, y = -2, z = 0},
			maxacc = {x = 0, y = -6, z = 0},
			minexptime = 0.1,
			maxexptime = 1,
			minsize = 0.5,
			maxsize = 1.5,
			texture = "telemosaic_particle_arrival.png",
			glow = 15,
		})
		
		-- prevent teleport spamming
		recent_teleports[player_name] = true
		minetest.after(1, 
			function(name)
				recent_teleports[name] = nil
			end,
			player_name)
		else
		-- beacon is in error, one way or another.
		-- but don't swap it out - we won't get it back otherwise!
		end
	end
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
		swap_beacon(pointed_thing.under, "")
            else
		swap_beacon(pointed_thing.under, "_err")
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
    elseif player:get_player_control().sneak then
		-- normal place
		local def = minetest.registered_nodes[itemstack:get_name()]
		if def then
			return def.on_place(itemstack, player, pointed_thing)
		end

    elseif not is_protected_beacon(pos, player) then
		-- teleport when right-clicked
		do_teleport(pos, player)
    end
    return itemstack
end


-- register protected and plain beacons with different suffixes, names and textures
for _,is_protected in pairs({ true, false }) do

	local node_name_suffix = ""
	local texture_overlay = ""
	local description_prefix = ""

	if is_protected then
		node_name_suffix = "_protected"
		texture_overlay = "^telemosaic_beacon_protected_overlay.png"
		description_prefix = "Protected "
	end

	minetest.register_node('telemosaic:beacon' .. node_name_suffix, {
	    description = description_prefix .. 'Telemosaic beacon (on)',
	    tiles = {
		'telemosaic_beacon_top.png' .. texture_overlay,
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

	minetest.register_node('telemosaic:beacon_err' .. node_name_suffix, {
	    description = description_prefix .. 'Telemosaic beacon (err)',
	    tiles = {
		'telemosaic_beacon_err.png' .. texture_overlay,
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

	minetest.register_node('telemosaic:beacon_off' .. node_name_suffix, {
	    description = description_prefix .. 'Telemosaic beacon',
	    tiles = {
		'telemosaic_beacon_off.png' .. texture_overlay,
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

end


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
    { name= 'dark_grey', value= '#00000080'},
    { name= 'black', value= '#000000c0'},
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


telemosaic.travel_allowed = function(player, src, dest)
	return true
end
