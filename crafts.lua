

minetest.register_craft({
    output = 'telemosaic:beacon_off',
    recipe = {
        {'default:diamond', 'doors:door_wood', 'default:diamond'},
        {'default:obsidian','default:obsidian','default:obsidian'}
    }
})

minetest.register_craft({
    output = 'telemosaic:beacon_off_protected',
    type = 'shapeless',
    recipe = {"telemosaic:beacon_off", "default:steel_ingot"}
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


-- how to recycle a key
minetest.register_craft({
    type = 'shapeless',
    recipe = {'telemosaic:key'},
    output = 'default:mese_crystal_fragment'
})