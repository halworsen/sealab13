vs_control/var/IgnitionLevel = 10 //Moles of oxygen+plasma - co2 needed to burn.

//Some legacy definitions so fires can be started.
atom/proc/temperature_expose(datum/gas_mixture/air, exposed_temperature, exposed_volume)
	return null


turf/proc/hotspot_expose(exposed_temperature, exposed_volume, soh = 0)



turf/simulated/hotspot_expose(exposed_temperature, exposed_volume, soh)
	if(fire_protection > world.time-300) return
	var/datum/gas_mixture/air_contents = return_air(1)
	if(!air_contents)
		return 0

  /*if(active_hotspot)
		if(soh)
			if(air_contents.toxins > 0.5 && air_contents.oxygen > 0.5)
				if(active_hotspot.temperature < exposed_temperature)
					active_hotspot.temperature = exposed_temperature
				if(active_hotspot.volume < exposed_volume)
					active_hotspot.volume = exposed_volume
		return 1*/
	var/igniting = 0
	if(locate(/obj/fire) in src)
		return 1
	var/datum/gas/volatile_fuel/fuel = locate() in air_contents.trace_gases
	var/obj/liquid_fuel/liquid = locate() in src
	if(air_contents.calculate_firelevel(liquid) > vsc.IgnitionLevel && (fuel || liquid || air_contents.toxins > 0.5))
		igniting = 1
		if(air_contents.oxygen < 0.5)
			return 0

		if(! (locate(/obj/fire) in src))
			var/obj/fire/F = new(src,1000)
			F.temperature = exposed_temperature
			F.volume = CELL_VOLUME

		//active_hotspot.just_spawned = (current_cycle < air_master.current_cycle)
		//remove just_spawned protection if no longer processing this cell

	return igniting

obj
	fire
		//Icon for fire on turfs.

		anchored = 1
		mouse_opacity = 0

		//luminosity = 3

		icon = 'fire.dmi'
		icon_state = "1"

		layer = TURF_LAYER

		var
			volume = CELL_VOLUME
			temperature = FIRE_MINIMUM_TEMPERATURE_TO_EXIST
			firelevel = 10000 //Calculated by gas_mixture.calculate_firelevel()
			archived_firelevel = 0

		process()

			if(firelevel > vsc.IgnitionLevel)

				var/turf/simulated/floor/S = loc
				if(!S.zone) del src //Cannot exist where zones are broken.

				if(istype(S,/turf/simulated/floor))
					var
						datum/gas_mixture/air_contents = S.return_air()
						//Get whatever trace fuels are in the area
						datum/gas/volatile_fuel/fuel = locate(/datum/gas/volatile_fuel/) in air_contents.trace_gases
						//Also get liquid fuels on the ground.
						obj/liquid_fuel/liquid = locate() in S

					firelevel = air_contents.calculate_firelevel(liquid)

					//Ensure that there is an appropriate amount of fuel and O2 here.
					if(firelevel > 25 && (air_contents.toxins || fuel || liquid))

						for(var/direction in cardinal)
							if(S.air_check_directions&direction) //Grab all valid bordering tiles

								var/turf/simulated/enemy_tile = get_step(S, direction)

								if(istype(enemy_tile))
									//If extinguisher mist passed over the turf it's trying to spread to, don't spread and
									//reduce firelevel.
									if(enemy_tile.fire_protection > world.time-30)
										firelevel -= 150
										continue

									//Spread the fire.
									if(!(locate(/obj/fire) in enemy_tile))
										if( prob( firelevel/2.5 ) )
											new/obj/fire(enemy_tile,firelevel)

					var/datum/gas_mixture/flow = air_contents.remove_ratio(0.5) //Take half the air from the room I guess.

					if(flow)

						//Ensure adequate oxygen and fuel.
						if(flow.oxygen > 0.3 && (flow.toxins || fuel || liquid))

							//Change icon depending on the fuel, and thus temperature.
							icon_state = "1"
							if(firelevel > 25)
								icon_state = "2"
							if(firelevel > 100)
								icon_state = "3"

							//Ensure flow temperature is higher than minimum fire temperatures.
							flow.temperature = max(PLASMA_MINIMUM_BURN_TEMPERATURE+0.1,flow.temperature)

							//Burn the gas mixture.
							flow.zburn(liquid)

						else

							del src


						S.assume_air(flow) //Then put it back where you found it.

					else
						del src
				else
					del src
			else
				del src

			for(var/mob/living/carbon/human/M in loc)
				M.FireBurn(min(max(0.1,firelevel / 20),10)) //Burn the humans!


		New(newLoc,fl)
			..()
			dir = pick(cardinal)
			sd_SetLuminosity(3)
			firelevel = fl
			for(var/mob/living/carbon/human/M in loc)
				M.FireBurn(min(max(0.1,firelevel / 20),10)) //Burn the humans!

		Del()
			if (istype(loc, /turf/simulated))
				src.sd_SetLuminosity(0)

				loc = null

			..()

obj/liquid_fuel
	//Liquid fuel is used for things that used to rely on volatile fuels or plasma being contained to a couple tiles.
	icon = 'icons/effects/effects.dmi'
	icon_state = "fuel"
	layer = TURF_LAYER+0.2
	anchored = 1
	var/amount = 1 //Basically moles.

	New(newLoc,amt=1)
		src.amount = amt

		//Be absorbed by any other liquid fuel in the tile.
		for(var/obj/liquid_fuel/other in newLoc)
			if(other != src)
				other.amount += src.amount
				spawn other.Spread()
				del src
				return

		Spread()
		. = ..()

	proc/Spread()
		//Allows liquid fuels to sometimes flow into other tiles.
		if(amount < 0.5) return
		var/turf/simulated/S = loc
		if(!istype(S)) return
		for(var/d in cardinal)
			if(S.air_check_directions & d)
				if(rand(25))
					var/turf/simulated/O = get_step(src,d)
					new/obj/liquid_fuel(O,amount*0.25)
					amount *= 0.75

	flamethrower_fuel
		icon_state = "mustard"
		anchored = 0
		New(newLoc, amt = 1, d = 0)
			dir = d //Setting this direction means you won't get torched by your own flamethrower.
			. = ..()
		Spread()
			//The spread for flamethrower fuel is much more precise, to create a wide fire pattern.
			if(amount < 0.1) return
			var/turf/simulated/S = loc
			if(!istype(S)) return

			for(var/d in list(turn(dir,90),turn(dir,-90)))
				if(S.air_check_directions & d)
					var/turf/simulated/O = get_step(S,d)
					new/obj/liquid_fuel/flamethrower_fuel(O,amount*0.25,d)
					O.hotspot_expose((T20C*2) + 380,500) //Light flamethrower fuel on fire immediately.

			amount *= 0.5


turf/simulated/var/fire_protection = 0 //Protects newly extinguished tiles from being overrun again.
turf/proc/apply_fire_protection()
turf/simulated/apply_fire_protection()
	fire_protection = world.time

datum/gas_mixture/proc/zburn(obj/liquid_fuel/liquid)
	//This proc is similar to fire(), but uses a simple logarithm to calculate temp, and is thus more stable with ZAS.
	if(temperature > PLASMA_MINIMUM_BURN_TEMPERATURE)
		var
			total_fuel = toxins
			fuel_sources = 0 //We'll divide by this later so that fuel is consumed evenly.
			datum/gas/volatile_fuel/fuel = locate() in trace_gases

		if(fuel)
		//Volatile Fuel
			total_fuel += fuel.moles
			fuel_sources++

		if(liquid)
		//Liquid Fuel
			if(liquid.amount <= 0)
				del liquid
			else
				total_fuel += liquid.amount
				fuel_sources++

			//Toxins
		if(toxins > 0.3) fuel_sources++

		if(!fuel_sources) return 0 //If there's no fuel, there's no burn. Can't divide by zero anyway.

		if(oxygen > 0.3)

				//Calculate the firelevel.
			var/firelevel = calculate_firelevel(liquid)

				//Reaches a maximum practical temperature of around 2750.

			temperature = 1000*log(0.016*firelevel + 1.45)

			//Consume some gas.
			var/consumed_gas = min(oxygen,0.002*firelevel,total_fuel) / fuel_sources

			oxygen -= consumed_gas

			toxins = max(0,toxins-consumed_gas)

			if(fuel)
				fuel.moles -= consumed_gas
				if(fuel.moles <= 0) del fuel

			if(liquid)
				liquid.amount -= consumed_gas
				if(liquid.amount <= 0) del liquid

			update_values()
			return consumed_gas*fuel_sources
	return 0

/*
OLD FIRE:
fire()
				var/energy_released = 0
				var/old_heat_capacity = heat_capacity()

				var/datum/gas/volatile_fuel/fuel_store = locate(/datum/gas/volatile_fuel/) in trace_gases
				if(fuel_store) //General volatile gas burn
					var/burned_fuel = 0

					if(oxygen < fuel_store.moles)
						burned_fuel = oxygen
						fuel_store.moles -= burned_fuel
						oxygen = 0
					else
						burned_fuel = fuel_store.moles
						oxygen -= fuel_store.moles
						del(fuel_store)

					energy_released += vsc.FIRE_CARBON_ENERGY_RELEASED * burned_fuel
					carbon_dioxide += burned_fuel
					fuel_burnt += burned_fuel

				//Handle plasma burning
				if(toxins > MINIMUM_HEAT_CAPACITY)
					var/plasma_burn_rate = 0
					var/oxygen_burn_rate = 0
					//more plasma released at higher temperatures
					var/temperature_scale
					if(temperature < PLASMA_UPPER_TEMPERATURE)
						temperature_scale = 1
					else
						temperature_scale = (temperature-PLASMA_MINIMUM_BURN_TEMPERATURE)/(PLASMA_UPPER_TEMPERATURE-PLASMA_MINIMUM_BURN_TEMPERATURE)
					if(temperature_scale > 0)
						oxygen_burn_rate = 1.4 - temperature_scale
						if(oxygen > toxins*PLASMA_OXYGEN_FULLBURN)
							plasma_burn_rate = (toxins*temperature_scale)/4
						else
							plasma_burn_rate = (temperature_scale*(oxygen/PLASMA_OXYGEN_FULLBURN))/4
						if(plasma_burn_rate > MINIMUM_HEAT_CAPACITY)
							toxins -= plasma_burn_rate
							oxygen -= plasma_burn_rate*oxygen_burn_rate
							carbon_dioxide += plasma_burn_rate

							energy_released += vsc.FIRE_PLASMA_ENERGY_RELEASED * (plasma_burn_rate)

							fuel_burnt += (plasma_burn_rate)*(1+oxygen_burn_rate)

				if(energy_released > 0)
					var/new_heat_capacity = heat_capacity()
					if(new_heat_capacity > MINIMUM_HEAT_CAPACITY)
						temperature = (temperature*old_heat_capacity + energy_released)/new_heat_capacity

				return fuel_burnt
 OLD ZBURN:
datum/gas_mixture/proc/zburn(obj/liquid_fuel/liquid)
	if(vsc.switch_fire)
		. = fire()
		if(liquid && liquid.amount > 0)
			oxygen -= fire_ratio_1
			liquid.amount = max(liquid.amount-fire_ratio_1,0)
			carbon_dioxide += fire_ratio_1
			if(liquid.amount <= 0)
				del liquid
		return
	if(temperature > PLASMA_MINIMUM_BURN_TEMPERATURE)
		var
			fuel_level = 0
			datum/gas/volatile_fuel/fuel = locate() in trace_gases
			liquid_level = 0
		if(fuel) fuel_level = fuel.moles
		if(liquid) liquid_level = liquid.amount
		if(liquid.amount <= 0)
			del liquid
			liquid_level = 0
		if(oxygen > 0.3 && (toxins || fuel_level || liquid_level))
			if(toxins && temperature < PLASMA_UPPER_TEMPERATURE)
				temperature += (vsc.FIRE_PLASMA_ENERGY_RELEASED*fire_ratio_1) / heat_capacity()

			if((fuel_level || liquid_level) && temperature < PLASMA_UPPER_TEMPERATURE)
				temperature += (vsc.FIRE_CARBON_ENERGY_RELEASED*fire_ratio_1) / heat_capacity()

			if(toxins > fire_ratio_1)
				oxygen -= vsc.OXY_TO_PLASMA*fire_ratio_1
				toxins -= fire_ratio_1
				carbon_dioxide += fire_ratio_1
			else if(toxins)
				oxygen -= toxins * vsc.OXY_TO_PLASMA
				carbon_dioxide += toxins
				toxins = 0

			if(fuel_level > fire_ratio_1/1.5)
				oxygen -= vsc.OXY_TO_PLASMA*fire_ratio_1
				fuel.moles -= fire_ratio_1
				carbon_dioxide += fire_ratio_1

			else if(fuel_level)
				oxygen -= fuel.moles * vsc.OXY_TO_PLASMA
				carbon_dioxide += fuel.moles
				fuel.moles = 0

			if(liquid_level > 0)
				oxygen -= fire_ratio_1
				liquid.amount = max(liquid.amount-fire_ratio_1,0)
				carbon_dioxide += fire_ratio_1
				if(liquid.amount <= 0)
					del liquid
			return 1
	return 0 */

datum/gas_mixture/proc/calculate_firelevel(obj/liquid_fuel/liquid)
		//Calculates the firelevel based on one equation instead of having to do this multiple times in different areas.
	var
		datum/gas/volatile_fuel/fuel = locate() in trace_gases
		fuel_level = 0
		liquid_level = 0

	if(fuel) fuel_level = fuel.moles
	if(liquid) liquid_level = liquid.amount
	return oxygen + toxins + liquid_level*15 + fuel_level*5

/mob/living/carbon/human/proc/FireBurn(mx as num)
	//Burns mobs due to fire. Respects heat transfer coefficients on various body parts.

	var
		head_exposure = 1
		chest_exposure = 1
		groin_exposure = 1
		legs_exposure = 1
		arms_exposure = 1

	//Get heat transfer coefficients for clothing.
	for(var/obj/item/clothing/C in src)
		if(l_hand == C || r_hand == C) continue
		if(C.body_parts_covered & HEAD)
			head_exposure *= C.heat_transfer_coefficient
		if(C.body_parts_covered & UPPER_TORSO)
			chest_exposure *= C.heat_transfer_coefficient
		if(C.body_parts_covered & LOWER_TORSO)
			groin_exposure *= C.heat_transfer_coefficient
		if(C.body_parts_covered & LEGS)
			legs_exposure *= C.heat_transfer_coefficient
		if(C.body_parts_covered & ARMS)
			arms_exposure *= C.heat_transfer_coefficient

	//Always check these damage procs first if fire damage isn't working. They're probably what's wrong.

	apply_damage(2.5*mx*head_exposure, BURN, "head", 0, 0, "Fire")
	apply_damage(2.5*mx*chest_exposure, BURN, "chest", 0, 0, "Fire")
	apply_damage(2.0*mx*groin_exposure, BURN, "groin", 0, 0, "Fire")
	apply_damage(0.6*mx*legs_exposure, BURN, "l_leg", 0, 0, "Fire")
	apply_damage(0.6*mx*legs_exposure, BURN, "r_leg", 0, 0, "Fire")
	apply_damage(0.4*mx*arms_exposure, BURN, "l_arm", 0, 0, "Fire")
	apply_damage(0.4*mx*arms_exposure, BURN, "r_arm", 0, 0, "Fire")

	flash_pain()