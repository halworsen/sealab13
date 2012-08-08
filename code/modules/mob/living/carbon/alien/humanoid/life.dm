//This file was auto-corrected by findeclaration.exe on 25.5.2012 20:42:32

/mob/living/carbon/alien/humanoid
	var/oxygen_alert = 0
	var/toxins_alert = 0
	var/fire_alert = 0

	var/temperature_alert = 0


/mob/living/carbon/alien/humanoid/Life()
	set invisibility = 0
	set background = 1

	if (monkeyizing)
		return

	..()

	if (stat != DEAD) //still breathing

		if(air_master.current_cycle%4==2)
			//Only try to take a breath every 4 seconds, unless suffocating
			spawn(0) breathe()

		else //Still give containing object the chance to interact
			if(istype(loc, /obj/))
				var/obj/location_as_object = loc
				location_as_object.handle_internal_lifeform(src, 0)

		//Chemicals in the body
		handle_chemicals_in_body()

	blinded = null

	//Disease Check
	//handle_virus_updates() There is no disease that affects aliens

	//Handle temperature/pressure differences between body and environment
	handle_environment()

	//stuff in the stomach
	handle_stomach()


	//Status updates, death etc.
	handle_regular_status_updates()
	update_canmove()

	// Grabbing
	for(var/obj/item/weapon/grab/G in src)
		G.process()

	if(client)
		handle_regular_hud_updates()


/mob/living/carbon/alien/humanoid

	proc/breathe()
		if(reagents)
			if(reagents.has_reagent("lexorin")) return
		if(istype(loc, /obj/machinery/atmospherics/unary/cryo_cell)) return

		var/datum/gas_mixture/environment = loc.return_air()
		var/datum/air_group/breath

		// This is mostly here for the smoke grenades and getting toxins in the air.

		if(!breath)
			if(istype(loc, /obj/))
				var/obj/location_as_object = loc
				breath = location_as_object.handle_internal_lifeform(src, BREATH_VOLUME)
			else if(istype(loc, /turf/))
				var/breath_moles = 0
				/*if(environment.return_pressure() > ONE_ATMOSPHERE)
					// Loads of air around (pressure effect will be handled elsewhere), so lets just take a enough to fill our lungs at normal atmos pressure (using n = Pv/RT)
					breath_moles = (ONE_ATMOSPHERE*BREATH_VOLUME/R_IDEAL_GAS_EQUATION*environment.temperature)
				else*/
					// Not enough air around, take a percentage of what's there to model this properly
				breath_moles = environment.total_moles()*BREATH_PERCENTAGE

				breath = loc.remove_air(breath_moles)

				// Handle chem smoke effect  -- Doohl
				for(var/obj/effect/effect/chem_smoke/smoke in view(1, src))
					if(smoke.reagents.total_volume)
						smoke.reagents.reaction(src, INGEST)
						spawn(5)
							if(smoke)
								smoke.reagents.copy_to(src, 10) // I dunno, maybe the reagents enter the blood stream through the lungs?
						break // If they breathe in the nasty stuff once, no need to continue checking


			else //Still give containing object the chance to interact
				if(istype(loc, /obj/))
					var/obj/location_as_object = loc
					location_as_object.handle_internal_lifeform(src, 0)

		handle_breath(breath)

		if(breath)
			loc.assume_air(breath)

	proc/handle_breath(datum/gas_mixture/breath)
		// Mostly for getting toxins from the air into your plasma storage.
		if(nodamage)
			return

		if(!breath || (breath.total_moles() == 0))
			//Aliens breathe in vaccuum
			return 0

		var/toxins_used = 0
		var/breath_pressure = (breath.total_moles()*R_IDEAL_GAS_EQUATION*breath.temperature)/BREATH_VOLUME

		//Partial pressure of the toxins in our breath
		var/Toxins_pp = (breath.toxins/breath.total_moles())*breath_pressure

		if(Toxins_pp) // Detect toxins in air

			adjustToxLoss(breath.toxins*250)
			toxins_alert = max(toxins_alert, 1)

			toxins_used = breath.toxins

		else
			toxins_alert = 0

		//Breathe in toxins and out oxygen
		breath.toxins -= toxins_used
		breath.oxygen += toxins_used

		return 1

	proc/handle_environment()

		//If there are alien weeds on the ground then heal if needed or give some toxins
		if(locate(/obj/effect/alien/weeds) in loc)
			if(health >= 100)
				adjustToxLoss(15)

			else
				adjustBruteLoss(-5)
				adjustFireLoss(-5)
				adjustOxyLoss(-5) // This shouldn't be needed, it's a failsafe.

	proc/get_thermal_protection()
		var/thermal_protection = 1000.0
		return thermal_protection

	proc/add_fire_protection(var/temp)
		var/fire_prot = 0
		if(head)
			if(head.protective_temperature > temp)
				fire_prot += (head.protective_temperature/10)
		if(wear_mask)
			if(wear_mask.protective_temperature > temp)
				fire_prot += (wear_mask.protective_temperature/10)
		if(wear_suit)
			if(wear_suit.protective_temperature > temp)
				fire_prot += (wear_suit.protective_temperature/10)


		return fire_prot

	proc/handle_chemicals_in_body()

		if(reagents) reagents.metabolize(src)

		if (drowsyness)
			drowsyness--
			eye_blurry = max(2, eye_blurry)
			if (prob(5))
				sleeping += 1
				Paralyse(5)

		confused = max(0, confused - 1)
		// decrement dizziness counter, clamped to 0
		if(resting)
			dizziness = max(0, dizziness - 5)
			jitteriness = max(0, jitteriness - 5)
		else
			dizziness = max(0, dizziness - 1)
			jitteriness = max(0, jitteriness - 1)

		updatehealth()

		return //TODO: DEFERRED


	proc/handle_regular_status_updates()
		updatehealth()

		if(stat == DEAD)	//DEAD. BROWN BREAD. SWIMMING WITH THE SPESS CARP
			blinded = 1
			silent = 0
		else				//ALIVE. LIGHTS ARE ON
			if(health < config.health_threshold_dead || brain_op_stage == 4.0)
				death()
				blinded = 1
				stat = DEAD
				silent = 0
				return 1

			//UNCONSCIOUS. NO-ONE IS HOME
			if( (getOxyLoss() > 75) || (config.health_threshold_crit > health) )
				if( health <= 20 && prob(1) )
					spawn(0)
						emote("gasp")
				if(!reagents.has_reagent("inaprovaline"))
					adjustOxyLoss(1)
				Paralyse(3)
			else
				adjustOxyLoss(-1)

			if(paralysis)
				AdjustParalysis(-1)
				blinded = 1
				stat = UNCONSCIOUS
			else if(sleeping)
				sleeping = max(sleeping-1, 0)
				blinded = 1
				stat = UNCONSCIOUS
				if( prob(10) && health )
					spawn(0)
						emote("hiss")
			//CONSCIOUS
			else
				stat = CONSCIOUS

			/*	What in the living hell is this?*/
			if(move_delay_add > 0)
				move_delay_add = max(0, move_delay_add - rand(1, 2))

			//Eyes
			if(sdisabilities & BLIND)		//disabled-blind, doesn't get better on its own
				blinded = 1
			else if(eye_blind)			//blindness, heals slowly over time
				eye_blind = max(eye_blind-1,0)
				blinded = 1
			else if(eye_blurry)	//blurry eyes heal slowly
				eye_blurry = max(eye_blurry-1, 0)

			//Ears
			if(sdisabilities & DEAF)		//disabled-deaf, doesn't get better on its own
				ear_deaf = max(ear_deaf, 1)
			else if(ear_deaf)			//deafness, heals slowly over time
				ear_deaf = max(ear_deaf-1, 0)
			else if(ear_damage < 25)	//ear damage heals slowly under this threshold. otherwise you'll need earmuffs
				ear_damage = max(ear_damage-0.05, 0)

			//Other
			if(stunned)
				AdjustStunned(-1)

			if(weakened)
				weakened = max(weakened-1,0)	//before you get mad Rockdtben: I done this so update_canmove isn't called multiple times

			if(stuttering)
				stuttering = max(stuttering-1, 0)

			if(silent)
				silent = max(silent-1, 0)

			if(druggy)
				druggy = max(druggy-1, 0)
		return 1


	proc/handle_regular_hud_updates()

		if (stat == 2 || (XRAY in mutations))
			sight |= SEE_TURFS
			sight |= SEE_MOBS
			sight |= SEE_OBJS
			see_in_dark = 8
			see_invisible = SEE_INVISIBLE_LEVEL_TWO
		else if (stat != 2)
			sight |= SEE_MOBS
			sight &= ~SEE_TURFS
			sight &= ~SEE_OBJS
			see_in_dark = 4
			see_invisible = SEE_INVISIBLE_LEVEL_TWO

		if (sleep) sleep.icon_state = text("sleep[]", sleeping)
		if (rest) rest.icon_state = text("rest[]", resting)

		if (healths)
			if (stat != 2)
				switch(health)
					if(100 to INFINITY)
						healths.icon_state = "health0"
					if(75 to 100)
						healths.icon_state = "health1"
					if(50 to 75)
						healths.icon_state = "health2"
					if(25 to 50)
						healths.icon_state = "health3"
					if(0 to 25)
						healths.icon_state = "health4"
					else
						healths.icon_state = "health5"
			else
				healths.icon_state = "health6"

		if(pullin)	pullin.icon_state = "pull[pulling ? 1 : 0]"


		if (toxin)	toxin.icon_state = "tox[toxins_alert ? 1 : 0]"
		if (oxygen) oxygen.icon_state = "oxy[oxygen_alert ? 1 : 0]"
		if (fire) fire.icon_state = "fire[fire_alert ? 1 : 0]"
		//NOTE: the alerts dont reset when youre out of danger. dont blame me,
		//blame the person who coded them. Temporary fix added.

		client.screen -= hud_used.blurry
		client.screen -= hud_used.druggy
		client.screen -= hud_used.vimpaired

		if ((blind && stat != 2))
			if ((blinded))
				blind.layer = 18
			else
				blind.layer = 0

				if (disabilities & NEARSIGHTED)
					client.screen += hud_used.vimpaired

				if (eye_blurry)
					client.screen += hud_used.blurry

				if (druggy)
					client.screen += hud_used.druggy

		if (stat != 2)
			if (machine)
				if (!( machine.check_eye(src) ))
					reset_view(null)
			else
				if(!client.adminobs)
					reset_view(null)

		return 1

	proc/handle_virus_updates()
		if(bodytemperature > 406)
			for(var/datum/disease/D in viruses)
				D.cure()
		return

	proc/handle_stomach()
		spawn(0)
			for(var/mob/living/M in stomach_contents)
				if(M.loc != src)
					stomach_contents.Remove(M)
					continue
				if(istype(M, /mob/living/carbon) && stat != 2)
					if(M.stat == 2)
						M.death(1)
						stomach_contents.Remove(M)
						del(M)
						continue
					if(air_master.current_cycle%3==1)
						if(!M.nodamage)
							M.adjustBruteLoss(5)
						adjustBruteLoss(-10)
						adjustFireLoss(-10)
						adjustOxyLoss(-10)
