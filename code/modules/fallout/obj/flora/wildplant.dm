//Fallout 13 wild plants directory

/turf/open
	var/list/allowed_plants

/obj/structure/flora/wild_plant
	name = "wild plant"
	density = 0
	anchored = 1
	var/age
	var/health = 100
	var/harvest
	var/dead
	var/lastcycle
	var/cycledelay = 1200
	var/obj/item/seeds/myseed
	var/lastproduce

/obj/structure/flora/wild_plant/Initialize(mapload, obj/item/seeds/new_seed)
	. = ..()
	if(new_seed)
		if(ispath(new_seed))
			new_seed = new_seed
		myseed = new_seed
	else
		if(!ispath(myseed, /obj/item/seeds))
			stack_trace("invalid seed type [myseed]")
			return INITIALIZE_HINT_QDEL
		myseed = new myseed

	myseed.forceMove(src)
	name = myseed.plantname
	icon = myseed.growing_icon
	START_PROCESSING(SSobj, src)
	update_icon()

/obj/structure/flora/wild_plant/Destroy()
	if(myseed)
		QDEL_NULL(myseed)
	STOP_PROCESSING(SSobj, src)
	return ..()

/obj/structure/flora/wild_plant/attackby(obj/item/O, mob/user, params)
	if(istype(O, /obj/item/shovel))
		to_chat(user, span_notice("You clear up [src]!"))
		qdel(src)
		return
	return ..()

/obj/structure/flora/wild_plant/attack_hand(mob/user)
	if(!iscarbon(user))
		return
	if(harvest)
		if(myseed.harvest(user))
			harvest = 0
			update_icon()
	else if(dead)
		dead = 0
		to_chat(user, "<span class='notice'>You remove the dead plant.</span>")
		qdel(myseed)
		qdel(src)
	else
		to_chat(user, "<span class='notice'>You touched the plant... Are you happy now?</span>") // Does this make you happy, Stanley?

/obj/structure/flora/wild_plant/examine(user)
	. = ..()
	if(myseed)
		. += "<span class='info'>It has <span class='name'>[myseed.plantname]</span> planted.</span>"
		if (dead)
			. += "<span class='warning'>It's dead!</span>"
		else if (harvest)
			. += "<span class='info'>It's ready to harvest.</span>"
		else if (health <= (myseed.endurance / 2))
			. += "<span class='warning'>It looks unhealthy.</span>"

/obj/structure/flora/wild_plant/proc/plantdies()
	health = 0
	harvest = 0
	if(!dead)
		update_icon()
		dead = 1
		spawn(3000)
			qdel(src)

/obj/structure/flora/wild_plant/process()

	if(!myseed)
		qdel(src)
		return
	var/needs_update = 0

	if(myseed.loc != src)
		myseed.forceMove(src)

	if(world.time > (lastcycle + cycledelay))
		lastcycle = world.time
		if(!dead)
			age++
			needs_update = 1

			if(health <= 0)
				plantdies()

			if(age > myseed.lifespan)
				health -= 50 / myseed.endurance

			// Harvest code
			if(age > myseed.production && (age - lastproduce) > myseed.production && (!harvest && !dead))
				if(myseed && myseed.yield != -1) // Unharvestable shouldn't be harvested
					harvest = 1
				else
					lastproduce = age
	if (needs_update)
		update_icon()
	return

/obj/structure/flora/wild_plant/update_icon()
	if(dead)
		icon_state = icon_state = myseed.icon_dead
	else if(harvest)
		if(!myseed.icon_harvest)
			icon_state = "[myseed.icon_grow][myseed.growthstages]"
		else
			icon_state = myseed.icon_harvest
	else
		var/t_growthstate = min(max(round((age / myseed.maturation) * myseed.growthstages), 1), myseed.growthstages)
		icon_state = "[myseed.icon_grow][t_growthstate]"
	if(myseed && myseed.get_gene(/datum/plant_gene/trait/glow))
		var/datum/plant_gene/trait/glow/G = myseed.get_gene(/datum/plant_gene/trait/glow)
		set_light(G.glow_range(myseed), G.glow_power(myseed), G.glow_color)
	else
		set_light(0)
