/obj/item/projectile/beam
	name = "laser"
	icon_state = "laser"
	pass_flags = PASSTABLE | PASSGLASS | PASSGRILLE
	damage = 20
	damage_type = BURN
	flag = "laser"
	eyeblur = 2
	var/ID = 0
	var/main = 0

	process()
		main = 1
		ID = rand(0,1000)
		var/lets_not_be_a_derp = 1
		spawn(0)
			while(!bumped)
				for(var/mob/living/M in loc)
					Bump(M)
				if((!( current ) || loc == current))
					current = locate(min(max(x + xo, 1), world.maxx), min(max(y + yo, 1), world.maxy), z)
				if((x == 1 || x == world.maxx || y == 1 || y == world.maxy))
					del(src)
					return
				if(!lets_not_be_a_derp)
					var/obj/item/projectile/beam/new_beam = new src.type(loc)
					processing_objects.Remove(new_beam)
					new_beam.dir = dir
					new_beam.ID = ID
				else
					lets_not_be_a_derp = 0
				step_towards(src, current)
		processing_objects.Remove(src)
		return

	Del()
		if(main)
			sleep(3)
			for(var/obj/item/projectile/beam/beam in world)
				if(beam.ID == ID)
					del(beam)
		..()


/obj/item/projectile/beam/heavylaser
	name = "heavy laser"
	icon_state = "heavylaser"
	damage = 40


/obj/item/projectile/beam/pulse
	name = "pulse"
	icon_state = "u_laser"
	damage = 50


/obj/item/projectile/beam/deathlaser
	name = "death laser"
	icon_state = "heavylaser"
	damage = 60




