
minetest.register_abm({
  label = "Telemosaic beacon effect",
  nodenames = {"telemosaic:beacon"},
  interval = 2.0,
  chance = 2,
  catch_up = false,
  action = function(pos, node, active_object_count, active_object_count_wider)
    minetest.add_particlespawner({
			amount = 4,
			time = 2,
			minpos = vector.add(pos, {x=-0.2, y=0, z=-0.2}),
			maxpos = vector.add(pos, {x=0.2, y=0, z=0.2}),
			minvel = {x=0, y=1, z=0},
			maxvel = {x=0, y=2, z=0},
			minacc = {x=0, y=0, z=0},
			maxacc = {x=0, y=0, z=0},
			minexptime = 1,
			maxexptime = 2,
			minsize = 1,
			maxsize = 1.7,
			collisiondetection = false,
			collision_removal = false,
			object_collision = false,
			vertical = false,
			texture = "telemosaic_particle_arrival.png",
      glow = 9
		})
  end
})
