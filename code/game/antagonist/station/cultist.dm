#define CULTINESS_PER_CULTIST 20
#define CULTINESS_PER_SACRIFICE 20
#define CULTINESS_PER_TURF 1

var/datum/antagonist/cultist/cult

/proc/iscultist(var/mob/player)
	if(!cult || !player.mind)
		return 0
	if(player.mind in cult.current_antagonists)
		return 1

/datum/antagonist/cultist
	id = MODE_CULTIST
	role_text = "Cultist"
	role_text_plural = "Cultists"
	restricted_jobs = list("Chaplain", "AI", "Cyborg")
	protected_jobs = list("Internal Affairs Agent", "Head of Security", "Captain", "Security Officer", "Warden", "Detective")
	feedback_tag = "cult_objective"
	antag_indicator = "cult"
	welcome_text = "You have a tome in your possession; one that will help you start the cult on this station. Use it well and remember - there are others."
	victory_text = "The cult wins! It has succeeded in serving its dark masters!"
	loss_text = "The staff managed to stop the cult!"
	victory_feedback_tag = "win - cult win"
	loss_feedback_tag = "loss - staff stopped the cult"
	flags = ANTAG_SUSPICIOUS | ANTAG_RANDSPAWN | ANTAG_VOTABLE
	hard_cap = 5
	hard_cap_round = 6
	initial_spawn_req = 4
	initial_spawn_target = 6
	antaghud_indicator = "hudcultist"

	var/allow_narsie = 1
	var/powerless = 0
	var/datum/mind/sacrifice_target
	var/list/obj/effect/rune/teleport/teleport_runes = list()
	var/list/rune_strokes = list()
	var/list/sacrificed
	var/cult_rating = 0
	var/cult_level = 1
	var/conversion_blurb = "You catch a glimpse of the Realm of Nar-Sie, the Geometer of Blood. You now see how flimsy the world is, you see that it should be open to the knowledge of That Which Waits. Assist your new compatriots in their dark dealings. Their goals are yours, and yours are theirs. You serve the Dark One above all else. Bring It back."

	faction = "cult"

/datum/antagonist/cultist/New()
	..()
	cult = src

/datum/antagonist/cultist/create_global_objectives()

	if(!..())
		return

	global_objectives = list()
	if(prob(50))
		global_objectives |= new /datum/objective/cult/survive
	else
		global_objectives |= new /datum/objective/cult/eldergod

	var/datum/objective/cult/sacrifice/sacrifice = new()
	sacrifice.find_target()
	sacrifice_target = sacrifice.target
	global_objectives |= sacrifice

/datum/antagonist/cultist/equip(var/mob/living/carbon/human/player)

	if(!..())
		return 0

	var/obj/item/weapon/book/tome/T = new(get_turf(player))
	var/list/slots = list (
		"backpack" = slot_in_backpack,
		"left pocket" = slot_l_store,
		"right pocket" = slot_r_store,
		"left hand" = slot_l_hand,
		"right hand" = slot_r_hand,
	)
	for(var/slot in slots)
		player.equip_to_slot(T, slot)
		if(T.loc == player)
			break
	var/obj/item/weapon/storage/S = locate() in player.contents
	if(istype(S))
		T.loc = S

	/* Removed until a proper AOOC rewrite is made
	if(cult_level < 2)
		player.verbs += /mob/proc/set_cult_conversion_blurb
		player.verbs += /mob/proc/cult_ooc
		*/

/datum/antagonist/cultist/remove_antagonist(var/datum/mind/player, var/show_message, var/implanted)
	if(!..())
		return 0
	to_chat(player.current, "<span class='danger'>An unfamiliar white light flashes through your mind, cleansing the taint of the dark-one and the memories of your time as his servant with it.</span>")
	player.memory = ""
	if(show_message)
		player.current.visible_message("<span class='notice'>[player.current] looks like they just reverted to their old faith!</span>")
	remove_cult_magic(player.current)
	remove_cultiness(CULTINESS_PER_CULTIST)

/datum/antagonist/cultist/add_antagonist(var/datum/mind/player)
	. = ..()
	if(.)
		to_chat(player, "<span class='cult'>[conversion_blurb]</span>")
		if(player.current && !istype(player.current, /mob/living/simple_animal/construct))
			player.current.add_language(LANGUAGE_CULT)

/datum/antagonist/cultist/remove_antagonist(var/datum/mind/player, var/show_message, var/implanted)
	. = ..()
	if(. && player.current && !istype(player.current, /mob/living/simple_animal/construct))
		player.current.remove_language(LANGUAGE_CULT)

/datum/antagonist/cultist/update_antag_mob(var/datum/mind/player)
	..()
	add_cultiness(CULTINESS_PER_CULTIST)
	add_cult_magic(player.current)

/datum/antagonist/cultist/proc/add_cultiness(var/amount)
	cult_rating += amount
	if(cult_rating >= 100 && cult_level < 2)
		cult_level = 2
		for(var/datum/mind/H in cult.current_antagonists)
			if(H.current)
				to_chat(H.current, "<span class='cult'>The veil between this world and beyond grows thin, and your power grows.</span>")
				add_cult_magic(H.current)
		for(var/mob/dead/observer/D)
			add_ghost_magic(D)
	if(cult_rating >= 200 && cult_level < 3)
		cult_level = 3
		for(var/datum/mind/H in cult.current_antagonists)
			if(H.current)
				to_chat(H.current, "<span class='cult'>You feel that the fabric of reality is tearing.</span>")
				add_cult_magic(H.current)
		for(var/mob/dead/observer/D)
			add_ghost_magic(D)
	if(cult_rating >= 300 && cult_level < 4)
		cult_level = 4
		for(var/datum/mind/H in cult.current_antagonists)
			if(H.current)
				to_chat(H.current, "<span class='cult'>The world is at end. The veil is as thin as ever.</span>")
				add_cult_magic(H.current)
		for(var/mob/dead/observer/D)
			add_ghost_magic(D)

/datum/antagonist/cultist/proc/offer_uncult(var/mob/M)
	if(!iscultist(M) || !M.mind)
		return

	to_chat(M, "<span class='cult'>Do you want to abandon the cult of Nar'Sie? <a href='?src=\ref[src];confirmleave=1'>YOU ARE MAKING A MISTAKE</a></span>")

/datum/antagonist/cultist/Topic(href, href_list)
	if(href_list["confirmleave"])
		cult.remove_antagonist(usr.mind, 1)

/datum/antagonist/cultist/proc/remove_cultiness(var/amount)
	cult_rating = max(0, cult_rating - amount)

/datum/antagonist/cultist/proc/add_cult_magic(var/mob/M)
	M.verbs += Tier1Runes

	if(cult_level >= 2)
		M.verbs += Tier2Runes

		/*
		M.verbs -= /mob/proc/set_cult_conversion_blurb
		M.verbs -= /mob/proc/cult_ooc
		*/

		if(cult_level >= 3)
			M.verbs += Tier3Runes

			if(cult_level >= 4)
				M.verbs += Tier4Runes

/datum/antagonist/cultist/proc/remove_cult_magic(var/mob/M)
	M.verbs -= Tier1Runes
	M.verbs -= Tier2Runes
	M.verbs -= Tier3Runes
	M.verbs -= Tier4Runes

	/*
	M.verbs -= /mob/proc/set_cult_conversion_blurb
	M.verbs -= /mob/proc/cult_ooc
	*/

/mob/proc/set_cult_conversion_blurb()
	set name = "Set conversion blurb"
	set desc = "Sets a blurb that appears to fresh converts. This is only for providing fluff, do not put any round information here. This verb will be removed once you hit the second cult stage."
	set category = "OOC"

	if(!iscultist(src))
		verbs -= /mob/proc/set_cult_conversion_blurb
		return

	var/newblurb = input("Choose a new conversion blurb.", "Blurb", cult.conversion_blurb)

	if(newblurb)
		cult.conversion_blurb = newblurb

	log_and_message_admins("set cult's conversion blurb to '[newblurb]'")
	for(var/datum/mind/H in cult.current_antagonists)
		if(H.current)
			to_chat(H.current, "<span class='cult'>Conversion blurb is now: '[newblurb]'</span>")

/mob/proc/cult_ooc(var/msg as text)
	set name = "Cult OOC"
	set desc = "Allows you to communicate with other cultists OOCly. Do not use it to reveal any round-related information. This is purely for the fluff discussion. This verb will be removed once you hit the second cult stage. Unlike AOOC, other antagonist types can't see it."
	set category = "OOC"

	msg = sanitize(msg)
	if(!msg)
		return

	log_ooc("(CULT) [name]/[key] : [msg]")

	for(var/datum/mind/H in cult.current_antagonists)
		if(H.current)
			to_chat(H.current, "<span class='cult'>Cult OOC: [msg]</span>")
