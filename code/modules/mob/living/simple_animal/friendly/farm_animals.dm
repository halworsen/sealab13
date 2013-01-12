//goat
/mob/living/simple_animal/hostile/retaliate/goat
	name = "goat"
	desc = "Not known for their pleasant disposition."
	icon_state = "goat"
	icon_living = "goat"
	icon_dead = "goat_dead"
	speak = list("EHEHEHEHEH","eh?")
	speak_emote = list("brays")
	emote_hear = list("brays")
	emote_see = list("shakes its head", "stamps a foot", "glares around")
	speak_chance = 1
	turns_per_move = 5
	see_in_dark = 6
	meat_type = /obj/item/weapon/reagent_containers/food/snacks/meat
	meat_amount = 4
	response_help  = "pets the"
	response_disarm = "gently pushes aside the"
	response_harm   = "kicks the"
	faction = "neutral"
	attacktext = "kicks"
	health = 40
	melee_damage_lower = 1
	melee_damage_upper = 5

/mob/living/simple_animal/hostile/retaliate/goat/Life()
	..()
	//chance to go crazy and start wacking stuff
	if(prob(1))
		src.visible_message("\red [src] gets an evil-looking gleam in their eye.")
		faction = "hostile"
	if(faction == "hostile" && prob(10))
		faction = "neutral"
		enemies = list()
		stance = HOSTILE_STANCE_IDLE
		target_mob = null

/mob/living/simple_animal/hostile/retaliate/goat/attackby(var/obj/item/O as obj, var/mob/user as mob)
	if(istype(O, /obj/item/weapon/reagent_containers/glass))
		user.visible_message("[user] milks [src] into the [O].")
		var/obj/item/weapon/reagent_containers/glass/G = O
		G.reagents.add_reagent("milk",rand(7,12))
		if(G.reagents.total_volume >= G.volume)
			user << "\red The [O] is full."
	else
		..()
//cow
/mob/living/simple_animal/cow
	name = "cow"
	desc = "Known for their milk, just don't tip them over."
	icon_state = "cow"
	icon_living = "cow"
	icon_dead = "cow_dead"
	icon_gib = "cow_gib"
	speak = list("moo?","moo","MOOOOOO")
	speak_emote = list("moos","moos hauntingly")
	emote_hear = list("brays")
	emote_see = list("shakes its head")
	speak_chance = 1
	turns_per_move = 5
	see_in_dark = 6
	meat_type = /obj/item/weapon/reagent_containers/food/snacks/meat
	meat_amount = 6
	response_help  = "pets the"
	response_disarm = "gently pushes aside the"
	response_harm   = "kicks the"
	attacktext = "kicks"
	health = 50

/mob/living/simple_animal/cow/attackby(var/obj/item/O as obj, var/mob/user as mob)
	if(istype(O, /obj/item/weapon/reagent_containers/glass))
		user.visible_message("[user] milks [src] into the [O].")
		var/obj/item/weapon/reagent_containers/glass/G = O
		G.reagents.add_reagent("milk",rand(5,10))
		if(G.reagents.total_volume >= G.volume)
			user << "\red The [O] is full."
	else
		..()

/mob/living/simple_animal/cow/attack_hand(mob/living/carbon/M as mob)
	if(!stat && M.a_intent == "help")
		M.visible_message("\red [M] tips over [src].","\red You tip over [src].")
		src.Weaken(30)
		icon_state = "cow_dead"
		spawn(rand(20,50))
			if(!stat)
				icon_state = "cow"
				var/list/responses = list(	"\red [src] looks at you imploringly.",
											"\red [src] looks at you pleadingly",
											"\red [src] looks at you with a resigned expression.",
											"\red [src] seems resigned to it's fate.")
				M << pick(responses)
	else
		..()

/mob/living/simple_animal/chick
	name = "chick"
	desc = "Adorable! They make such a racket though"
	icon_state = "chick"
	icon_living = "chick"
	icon_dead = "chick_dead"
	icon_gib = "chick_gib"
	speak = list("cherp","cherp?","chirrup","cheep")
	speak_emote = list("cheeps")
	emote_hear = list("cheeps")
	emote_see = list("pecks at the ground","flaps it's tiny wings")
	speak_chance = 10
	turns_per_move = 1
	meat_type = /obj/item/weapon/reagent_containers/food/snacks/meat
	meat_amount = 1
	response_help  = "pets the"
	response_disarm = "gently pushes aside the"
	response_harm   = "kicks the"
	attacktext = "kicks"
	health = 1
	var/amount_grown = 0
	pass_flags = PASSTABLE | PASSGRILLE

	New()
		..()
		pixel_x = rand(-6,6)
		pixel_y = rand(-6,6)

/mob/living/simple_animal/chick/Life()
	..()
	if(!stat)
		amount_grown += rand(1,2)
		if(amount_grown >= 100)
			new /mob/living/simple_animal/chicken(src.loc)
			del(src)

/mob/living/simple_animal/chicken
	name = "chicken"
	desc = "Hopefully the eggs are good this season."
	icon_state = "chicken"
	icon_living = "chicken"
	icon_dead = "chicken_dead"
	speak = list("cluck","BWAAAAARK BWAK BWAK BWAK","bwaak bwak")
	speak_emote = list("clucks","croons")
	emote_hear = list("clucks")
	emote_see = list("pecks at the ground","flaps it's wings viciously")
	speak_chance = 10
	turns_per_move = 1
	meat_type = /obj/item/weapon/reagent_containers/food/snacks/meat
	meat_amount = 2
	response_help  = "pets the"
	response_disarm = "gently pushes aside the"
	response_harm   = "kicks the"
	attacktext = "kicks"
	health = 10
	pass_flags = PASSTABLE

	New()
		..()
		pixel_x = rand(-6,6)
		pixel_y = rand(-6,6)

/mob/living/simple_animal/chicken/Life()
	..()
	if(!stat && prob(1))
		src.visible_message("[src] [pick("lays an egg.","squats down and croons.","begins making a huge racket.","begins clucking raucously.")]")
		var/obj/item/weapon/reagent_containers/food/snacks/egg/E = new(src.loc)
		E.pixel_x = rand(-6,6)
		E.pixel_y = rand(-6,6)
		processing_objects.Add(E)

obj/item/weapon/reagent_containers/food/snacks/egg/var/amount_grown = 0
/obj/item/weapon/reagent_containers/food/snacks/egg/process()
	amount_grown += rand(1,2)
	if(amount_grown >= 100)
		if(prob(50))
			src.visible_message("[src] hatches with a quiet cracking sound.")
		new /mob/living/simple_animal/chick(src.loc)
		processing_objects.Remove(src)
		del(src)
