//This is fine right now, if we're adding organ specific damage this needs to be updated
/mob/living/carbon/alien/humanoid/New()
	var/datum/reagents/R = new/datum/reagents(100)
	reagents = R
	R.my_atom = src
	if(name == "alien")
		name = text("alien ([rand(1, 1000)])")
	real_name = name
	spawn (1)
		if(!istype(src, /mob/living/carbon/alien/humanoid/queen))
			stand_icon = new /icon('alien.dmi', "alien_s")
			lying_icon = new /icon('alien.dmi', "alien_l")
		icon = stand_icon
		update_clothing()
		src << "\blue Your icons have been generated!"
	..()

/mob/living/carbon/alien/humanoid/proc/mind_initialize(mob/G, alien_caste)
	mind = new
	mind.current = src
	mind.assigned_role = "Alien"
	mind.special_role = alien_caste
	mind.key = G.key

//This is fine, works the same as a human
/mob/living/carbon/alien/humanoid/Bump(atom/movable/AM as mob|obj, yes)
	spawn( 0 )
		if ((!( yes ) || now_pushing))
			return
		now_pushing = 0
		..()
		if (!istype(AM, /atom/movable))
			return
		if (!now_pushing)
			now_pushing = 1
			if (!AM.anchored)
				var/t = get_dir(src, AM)
				if (istype(AM, /obj/window))
					if(AM:ini_dir == NORTHWEST || AM:ini_dir == NORTHEAST || AM:ini_dir == SOUTHWEST || AM:ini_dir == SOUTHEAST)
						for(var/obj/window/win in get_step(AM,t))
							now_pushing = 0
							return
				step(AM, t)
			now_pushing = null
		return
	return

/mob/living/carbon/alien/humanoid/movement_delay()
	var/tally = 0
	if (istype(src, /mob/living/carbon/alien/humanoid/queen))
		tally += 5
	if (istype(src, /mob/living/carbon/alien/humanoid/drone))
		tally += 2
	if (istype(src, /mob/living/carbon/alien/humanoid/sentinel))
		tally += 1
	return tally

//This needs to be fixed
/mob/living/carbon/alien/humanoid/Stat()
	..()

	statpanel("Status")
	if (client && client.holder)
		stat(null, "([x], [y], [z])")

	stat(null, "Intent: [a_intent]")
	stat(null, "Move Mode: [m_intent]")

	if (client.statpanel == "Status")
		stat(null, "Plasma Stored: [toxloss]")

/mob/living/carbon/alien/humanoid/bullet_act(flag, A as obj)
	var/shielded = 0

	if(prob(50))
		for(var/mob/living/carbon/metroid/M in view(1,src))
			if(M.Victim == src)
				M.bullet_act(flag, A)
				return


	for(var/obj/item/device/shield/S in src)
		if (S.active)
			if (flag == "bullet")
				return
			shielded = 1
			S.active = 0
			S.icon_state = "shield0"
	for(var/obj/item/weapon/cloaking_device/S in src)
		if (S.active)
			shielded = 1
			S.active = 0
			S.icon_state = "shield0"
	if ((shielded && flag != "bullet"))
		if (!flag)
			src << "\blue Your shield was disturbed by a laser!"
			if(paralysis <= 12)	paralysis = 12
			updatehealth()
	if (locate(/obj/item/weapon/grab, src))
		var/mob/safe = null
		if (istype(l_hand, /obj/item/weapon/grab))
			var/obj/item/weapon/grab/G = l_hand
			if ((G.state == 3 && get_dir(src, A) == dir))
				safe = G.affecting
		if (istype(r_hand, /obj/item/weapon/grab))
			var/obj/item/weapon.grab/G = r_hand
			if ((G.state == 3 && get_dir(src, A) == dir))
				safe = G.affecting
		if (safe)
			return safe.bullet_act(flag, A)
	switch(flag)//Did these people not know that switch is a function that exists? I swear, half of the code ignores switch completely.
		if(PROJECTILE_BULLET)
			var/d = 51
			if (stat != 2)
				bruteloss += d
				updatehealth()
				if (prob(50)&&weakened <= 5)
					weakened = 5
		if(PROJECTILE_TASER)
			if (prob(75) && stunned <= 10)
				stunned = 10
			else
				weakened = 10
		if(PROJECTILE_DART)//Nothing is supposed to happen, just making sure it's listed.

		if(PROJECTILE_LASER)
			var/d = 20
	//		if (!eye_blurry) eye_blurry = 4 //This stuff makes no sense but lasers need a buff./ It really doesn't make any sense. /N
			if (prob(25)) stunned++
			if (stat != 2)
				bruteloss += d
				updatehealth()
				if (prob(25))
					stunned = 1
		if(PROJECTILE_PULSE)
			var/d = 40

			if (stat != 2)
				bruteloss += d
				updatehealth()
				if (prob(50))
					stunned = min(stunned, 5)
		if(PROJECTILE_BOLT)
			toxloss += 3
			radiation += 100
			updatehealth()
			drowsyness += 5
	return

/mob/living/carbon/alien/humanoid/emp_act(severity)
	if(wear_suit) wear_suit.emp_act(severity)
	if(head) head.emp_act(severity)
	if(r_store) r_store.emp_act(severity)
	if(l_store) l_store.emp_act(severity)
	..()

/mob/living/carbon/alien/humanoid/ex_act(severity)
	flick("flash", flash)

	if (stat == 2 && client)
		gib(1)
		return

	else if (stat == 2 && !client)
		gibs(loc, viruses)
		del(src)
		return

	var/shielded = 0
	for(var/obj/item/device/shield/S in src)
		if (S.active)
			shielded = 1
			break

	var/b_loss = null
	var/f_loss = null
	switch (severity)
		if (1.0)
			b_loss += 500
			gib(1)
			return

		if (2.0)
			if (!shielded)
				b_loss += 60

			f_loss += 60

			ear_damage += 30
			ear_deaf += 120

		if(3.0)
			b_loss += 30
			if (prob(50) && !shielded)
				paralysis += 1
			ear_damage += 15
			ear_deaf += 60

	bruteloss += b_loss
	fireloss += f_loss

	updatehealth()

/mob/living/carbon/alien/humanoid/blob_act()
	if (stat == 2)
		return
	var/shielded = 0
	for(var/obj/item/device/shield/S in src)
		if (S.active)
			shielded = 1
	var/damage = null
	if (stat != 2)
		damage = rand(30,40)

	if(shielded)
		damage /= 4


	show_message("\red The magma splashes on you!")

	fireloss += damage

	return

//unequip
/mob/living/carbon/alien/humanoid/u_equip(obj/item/W as obj)
	if (W == wear_suit)
		wear_suit = null
	else if (W == head)
		head = null
	else if (W == r_store)
		r_store = null
	else if (W == l_store)
		l_store = null
	else if (W == r_hand)
		r_hand = null
	else if (W == l_hand)
		l_hand = null

/mob/living/carbon/alien/humanoid/db_click(text, t1)
	var/obj/item/W = equipped()
	var/emptyHand = (W == null)
	if ((!emptyHand) && (!istype(W, /obj/item)))
		return
	if (emptyHand)
		usr.next_move = usr.prev_move
		usr:lastDblClick -= 3	//permit the double-click redirection to proceed.
	switch(text)

//if emptyhand then wear the suit, no bedsheet clothes for the alien

		if("o_clothing")
			if (wear_suit)
				if (emptyHand)
					wear_suit.DblClick()
			return
/*			if (!( istype(W, /obj/item/clothing/suit) ))
				return
			u_equip(W)
			wear_suit = W
			W.equipped(src, text)
*/
		if("head")
			if (head)
				if (emptyHand)
					head.DblClick()
				return
			if (( istype(W, /obj/alien/head) ))
				u_equip(W)
				head = W
				return
			return
/*			if (!( istype(W, /obj/item/clothing/head) ))
				return
			u_equip(W)
			head = W
			W.equipped(src, text)
*/
		if("storage1")
			if (l_store)
				if (emptyHand)
					l_store.DblClick()
				return
			if ((!( istype(W, /obj/item) ) || W.w_class > 3))
				return
			u_equip(W)
			l_store = W
		if("storage2")
			if (r_store)
				if (emptyHand)
					r_store.DblClick()
				return
			if ((!( istype(W, /obj/item) ) || W.w_class > 3))
				return
			u_equip(W)
			r_store = W
		else
	return

/mob/living/carbon/alien/humanoid/meteorhit(O as obj)
	for(var/mob/M in viewers(src, null))
		if ((M.client && !( M.blinded )))
			M.show_message(text("\red [] has been hit by []", src, O), 1)
	if (health > 0)
		bruteloss += (istype(O, /obj/meteor/small) ? 10 : 25)
		fireloss += 30

		updatehealth()
	return

/mob/living/carbon/alien/humanoid/Move(a, b, flag)
	if (buckled)
		return 0

	if (restrained())
		pulling = null

	var/t7 = 1
	if (restrained())
		for(var/mob/M in range(src, 1))
			if ((M.pulling == src && M.stat == 0 && !( M.restrained() )))
				t7 = null
	if ((t7 && (pulling && ((get_dist(src, pulling) <= 1 || pulling.loc == loc) && (client && client.moving)))))
		var/turf/T = loc
		. = ..()

		if (pulling && pulling.loc)
			if(!( isturf(pulling.loc) ))
				pulling = null
				return
			else
				if(Debug)
					diary <<"pulling disappeared? at __LINE__ in mob.dm - pulling = [pulling]"
					diary <<"REPORT THIS"

		/////
		if(pulling && pulling.anchored)
			pulling = null
			return

		if (!restrained())
			var/diag = get_dir(src, pulling)
			if ((diag - 1) & diag)
			else
				diag = null
			if ((get_dist(src, pulling) > 1 || diag))
				if (ismob(pulling))
					var/mob/M = pulling
					var/ok = 1
					if (locate(/obj/item/weapon/grab, M.grabbed_by))
						if (prob(75))
							var/obj/item/weapon/grab/G = pick(M.grabbed_by)
							if (istype(G, /obj/item/weapon/grab))
								for(var/mob/O in viewers(M, null))
									O.show_message(text("\red [] has been pulled from []'s grip by []", G.affecting, G.assailant, src), 1)
								//G = null
								del(G)
						else
							ok = 0
						if (locate(/obj/item/weapon/grab, M.grabbed_by.len))
							ok = 0
					if (ok)
						var/t = M.pulling
						M.pulling = null

						step(pulling, get_dir(pulling.loc, T))
						M.pulling = t
				else
					if (pulling)
						if (istype(pulling, /obj/window))
							if(pulling:ini_dir == NORTHWEST || pulling:ini_dir == NORTHEAST || pulling:ini_dir == SOUTHWEST || pulling:ini_dir == SOUTHEAST)
								for(var/obj/window/win in get_step(pulling,get_dir(pulling.loc, T)))
									pulling = null
					if (pulling)
						step(pulling, get_dir(pulling.loc, T))
	else
		pulling = null
		. = ..()
	if ((s_active && !( s_active in contents ) ))
		s_active.close(src)

	for(var/mob/living/carbon/metroid/M in view(1,src))
		M.UpdateFeed(src)

	return

/mob/living/carbon/alien/humanoid/update_clothing()
	..()

	if (monkeyizing)
		return

	overlays = null

	if(buckled)
		if(istype(buckled, /obj/stool/bed))
			lying = 1
		else
			lying = 0

	// Automatically drop anything in store / id / belt if you're not wearing a uniform.
	if (zone_sel)
		zone_sel.overlays = null
		zone_sel.overlays += body_standing
		zone_sel.overlays += image("icon" = 'zone_sel.dmi', "icon_state" = text("[]", zone_sel.selecting))

	if (lying)
		if(update_icon)
			icon = lying_icon

		overlays += body_lying

		if (face_lying)
			overlays += face_lying
	else
		if(update_icon)
			icon = stand_icon

		overlays += body_standing

		if (face_standing)
			overlays += face_standing

	// Uniform
	if (client)
		client.screen -= hud_used.other
		client.screen -= hud_used.intents
		client.screen -= hud_used.mov_int

	// ???
	if (client && other)
		client.screen += hud_used.other


	if (client)
		if (i_select)
			if (intent)
				client.screen += hud_used.intents

				var/list/L = dd_text2list(intent, ",")
				L[1] += ":-11"
				i_select.screen_loc = dd_list2text(L,",") //ICONS4, FUCKING SHIT
			else
				i_select.screen_loc = null
		if (m_select)
			if (m_int)
				client.screen += hud_used.mov_int

				var/list/L = dd_text2list(m_int, ",")
				L[1] += ":-11"
				m_select.screen_loc = dd_list2text(L,",") //ICONS4, FUCKING SHIT
			else
				m_select.screen_loc = null

	if (wear_suit)
		var/t1 = wear_suit.item_state
		if (!t1)
			t1 = wear_suit.icon_state
		overlays += image("icon" = 'mob.dmi', "icon_state" = text("[][]", t1, (!( lying ) ? null : "2")), "layer" = MOB_LAYER)
		if (wear_suit.blood_DNA)
			if (istype(wear_suit, /obj/item/clothing/suit/armor))
				overlays += image("icon" = 'blood.dmi', "icon_state" = "armorblood[!lying ? "" : "2"]", "layer" = MOB_LAYER)
			else
				overlays += image("icon" = 'blood.dmi', "icon_state" = "suitblood[!lying ? "" : "2"]", "layer" = MOB_LAYER)
		wear_suit.screen_loc = ui_iclothing
		if (istype(wear_suit, /obj/item/clothing/suit/straight_jacket))
			if (handcuffed)
				handcuffed.loc = loc
				handcuffed.layer = initial(handcuffed.layer)
				handcuffed = null
			if ((l_hand || r_hand))
				var/h = hand
				hand = 1
				drop_item()
				hand = 0
				drop_item()
				hand = h

	// Head
	if (head)
		var/t1 = head.item_state
		if (!t1)
			t1 = head.icon_state
		overlays += image("icon" = 'mob.dmi', "icon_state" = text("[][]", t1, (!( lying ) ? null : "2")), "layer" = MOB_LAYER)
		if (head.blood_DNA)
			overlays += image("icon" = 'blood.dmi', "icon_state" = "helmetblood[!lying ? "" : "2"]", "layer" = MOB_LAYER)
		head.screen_loc = ui_oclothing

	if (l_store)
		l_store.screen_loc = ui_storage1

	if (r_store)
		r_store.screen_loc = ui_storage2

	if (client)
		client.screen -= contents
		client.screen += contents

	if (r_hand)
		overlays += image("icon" = 'items_righthand.dmi', "icon_state" = r_hand.item_state ? r_hand.item_state : r_hand.icon_state, "layer" = MOB_LAYER+1)

		r_hand.screen_loc = ui_id

	if (l_hand)
		overlays += image("icon" = 'items_lefthand.dmi', "icon_state" = l_hand.item_state ? l_hand.item_state : l_hand.icon_state, "layer" = MOB_LAYER+1)

		l_hand.screen_loc = ui_belt



	var/shielded = 0
	for (var/obj/item/device/shield/S in src)
		if (S.active)
			shielded = 1
			break

	for (var/obj/item/weapon/cloaking_device/S in src)
		if (S.active)
			shielded = 2
			break

	if (shielded == 2 || alien_invis)
		invisibility = 2
		//New stealth. Hopefully doesn't lag too much. /N
		if(istype(loc, /turf))//If they are standing on a turf.
			AddCamoOverlay(loc)//Overlay camo.
	else
		invisibility = 0

	for (var/mob/M in viewers(1, src))
		if ((M.client && M.machine == src))
			spawn (0)
				show_inv(M)
				return

	last_b_state = stat

/mob/living/carbon/alien/humanoid/hand_p(mob/M as mob)
	if (!ticker)
		M << "You cannot attack people before the game has started."
		return

	if (M.a_intent == "hurt")
		if (istype(M.wear_mask, /obj/item/clothing/mask/muzzle))
			return
		if (health > 0)
			for(var/mob/O in viewers(src, null))
				if ((O.client && !( O.blinded )))
					O.show_message(text("\red <B>[M.name] has bit []!</B>", src), 1)
			bruteloss  += rand(1, 3)

			updatehealth()
	return

/mob/living/carbon/alien/humanoid/attack_paw(mob/living/carbon/monkey/M as mob)
	if(!ismonkey(M))	return//Fix for aliens receiving double messages when attacking other aliens.

	if (!ticker)
		M << "You cannot attack people before the game has started."
		return

	if (istype(loc, /turf) && istype(loc.loc, /area/start))
		M << "No attacking people at spawn, you jackass."
		return
	..()

	switch(M.a_intent)

		if ("help")
			help_shake_act(M)
		else
			if (istype(wear_mask, /obj/item/clothing/mask/muzzle))
				return
			if (health > 0)
				playsound(loc, 'bite.ogg', 50, 1, -1)
				for(var/mob/O in viewers(src, null))
					if ((O.client && !( O.blinded )))
						O.show_message(text("\red <B>[M.name] has bit [src]!</B>"), 1)
				bruteloss  += rand(1, 3)
				updatehealth()
	return


/mob/living/carbon/alien/humanoid/attack_metroid(mob/living/carbon/metroid/M as mob)
	if (!ticker)
		M << "You cannot attack people before the game has started."
		return

	if(M.Victim) return // can't attack while eating!

	if (health > -100)

		for(var/mob/O in viewers(src, null))
			if ((O.client && !( O.blinded )))
				O.show_message(text("\red <B>The [M.name] has [pick("bit","slashed")] []!</B>", src), 1)

		var/damage = rand(1, 3)

		if(istype(src, /mob/living/carbon/metroid/adult))
			damage = rand(20, 40)
		else
			damage = rand(5, 35)

		bruteloss += damage


		updatehealth()

	return

/mob/living/carbon/alien/humanoid/attack_hand(mob/living/carbon/human/M as mob)
	if (!ticker)
		M << "You cannot attack people before the game has started."
		return

	if (istype(loc, /turf) && istype(loc.loc, /area/start))
		M << "No attacking people at spawn, you jackass."
		return

	..()

	if(M.gloves && M.gloves.elecgen == 1)//Stungloves. Any contact will stun the alien.
		if(M.gloves.uses > 0)
			M.gloves.uses--
			if (weakened < 5)
				weakened = 5
			if (stuttering < 5)
				stuttering = 5
			if (stunned < 5)
				stunned = 5
			for(var/mob/O in viewers(src, null))
				if ((O.client && !( O.blinded )))
					O.show_message("\red <B>[src] has been touched with the stun gloves by [M]!</B>", 1, "\red You hear someone fall.", 2)

	switch(M.a_intent)

		if ("help")
			if (health > 0)
				help_shake_act(M)
			else
				if (M.health >= -75.0)
					if (((M.head && M.head.flags & 4) || ((M.wear_mask && !( M.wear_mask.flags & 32 )) || ((head && head.flags & 4) || (wear_mask && !( wear_mask.flags & 32 ))))))
						M << "\blue <B>Remove that mask!</B>"
						return
					var/obj/equip_e/human/O = new /obj/equip_e/human(  )
					O.source = M
					O.target = src
					O.s_loc = M.loc
					O.t_loc = loc
					O.place = "CPR"
					requests += O
					spawn( 0 )
						O.process()
						return

		if ("grab")
			if (M == src)
				return
			var/obj/item/weapon/grab/G = new /obj/item/weapon/grab( M )
			G.assailant = M
			if (M.hand)
				M.l_hand = G
			else
				M.r_hand = G
			G.layer = 20
			G.affecting = src
			grabbed_by += G
			G.synch()
			playsound(loc, 'thudswoosh.ogg', 50, 1, -1)
			for(var/mob/O in viewers(src, null))
				if ((O.client && !( O.blinded )))
					O.show_message(text("\red [] has grabbed [] passively!", M, src), 1)

		if ("hurt")
			var/damage = rand(1, 9)
			if (prob(90))
				if (M.mutations & HULK)//HULK SMASH
					damage += 14
					spawn(0)
						paralysis += 5
						step_away(src,M,15)
						sleep(3)
						step_away(src,M,15)
				playsound(loc, "punch", 25, 1, -1)
				for(var/mob/O in viewers(src, null))
					if ((O.client && !( O.blinded )))
						O.show_message(text("\red <B>[] has punched []!</B>", M, src), 1)
				if (damage > 9||prob(5))//Regular humans have a very small chance of weakening an alien.
					if (weakened < 10)
						weakened = rand(1,5)
					for(var/mob/O in viewers(M, null))
						if ((O.client && !( O.blinded )))
							O.show_message(text("\red <B>[] has weakened []!</B>", M, src), 1, "\red You hear someone fall.", 2)
				bruteloss += damage
				updatehealth()
			else
				playsound(loc, 'punchmiss.ogg', 25, 1, -1)
				for(var/mob/O in viewers(src, null))
					if ((O.client && !( O.blinded )))
						O.show_message(text("\red <B>[] has attempted to punch []!</B>", M, src), 1)

		if ("disarm")
			if (!lying)
				var/randn = rand(1, 100)
				if (randn <= 5)//Very small chance to push an alien down.
					weakened = 2
					playsound(loc, 'thudswoosh.ogg', 50, 1, -1)
					for(var/mob/O in viewers(src, null))
						if ((O.client && !( O.blinded )))
							O.show_message(text("\red <B>[] has pushed down []!</B>", M, src), 1)
				else
					if (randn <= 50)
						drop_item()
						playsound(loc, 'thudswoosh.ogg', 50, 1, -1)
						for(var/mob/O in viewers(src, null))
							if ((O.client && !( O.blinded )))
								O.show_message(text("\red <B>[] has disarmed []!</B>", M, src), 1)
					else
						playsound(loc, 'punchmiss.ogg', 25, 1, -1)
						for(var/mob/O in viewers(src, null))
							if ((O.client && !( O.blinded )))
								O.show_message(text("\red <B>[] has attempted to disarm []!</B>", M, src), 1)
	return

/*Code for aliens attacking aliens. Because aliens act on a hivemind, I don't see them as very aggressive with each other.
As such, they can either help or harm other aliens. Help works like the human help command while harm is a simple nibble.
In all, this is a lot like the monkey code. /N
*/

/mob/living/carbon/alien/humanoid/attack_alien(mob/living/carbon/alien/humanoid/M as mob)
	if (!ticker)
		M << "You cannot attack people before the game has started."
		return

	if (istype(loc, /turf) && istype(loc.loc, /area/start))
		M << "No attacking people at spawn, you jackass."
		return

	..()

	switch(M.a_intent)

		if ("help")
			sleeping = 0
			resting = 0
			if (paralysis >= 3) paralysis -= 3
			if (stunned >= 3) stunned -= 3
			if (weakened >= 3) weakened -= 3
			for(var/mob/O in viewers(src, null))
				if ((O.client && !( O.blinded )))
					O.show_message(text("\blue [M.name] nuzzles [] trying to wake it up!", src), 1)

		else
			if (health > 0)
				playsound(loc, 'bite.ogg', 50, 1, -1)
				var/damage = rand(1, 3)
				for(var/mob/O in viewers(src, null))
					if ((O.client && !( O.blinded )))
						O.show_message(text("\red <B>[M.name] has bit []!</B>", src), 1)
				bruteloss += damage
				updatehealth()
			else
				M << "\green <B>[name] is too injured for that.</B>"
	return


/mob/living/carbon/alien/humanoid/restrained()
	if (handcuffed)
		return 1
	return 0


/mob/living/carbon/alien/humanoid/var/co2overloadtime = null
/mob/living/carbon/alien/humanoid/var/temperature_resistance = T0C+75

/mob/living/carbon/alien/humanoid/show_inv(mob/user as mob)

	user.machine = src
	var/dat = {"
	<B><HR><FONT size=3>[name]</FONT></B>
	<BR><HR>
	<BR><B>Left Hand:</B> <A href='?src=\ref[src];item=l_hand'>[(l_hand ? text("[]", l_hand) : "Nothing")]</A>
	<BR><B>Right Hand:</B> <A href='?src=\ref[src];item=r_hand'>[(r_hand ? text("[]", r_hand) : "Nothing")]</A>
	<BR><B>Head:</B> <A href='?src=\ref[src];item=head'>[(head ? text("[]", head) : "Nothing")]</A>
	<BR><B>(Exo)Suit:</B> <A href='?src=\ref[src];item=suit'>[(wear_suit ? text("[]", wear_suit) : "Nothing")]</A>
	<BR><A href='?src=\ref[src];item=pockets'>Empty Pockets</A>
	<BR><A href='?src=\ref[user];mach_close=mob[name]'>Close</A>
	<BR>"}
	user << browse(dat, text("window=mob[name];size=340x480"))
	onclose(user, "mob[name]")
	return

/mob/living/carbon/alien/humanoid/updatehealth()
	if (nodamage == 0)
	//oxyloss is only used for suicide
	//toxloss isn't used for aliens, its actually used as alien powers!!
		health = 100 - oxyloss - fireloss - bruteloss
	else
		health = 100
		stat = 0

