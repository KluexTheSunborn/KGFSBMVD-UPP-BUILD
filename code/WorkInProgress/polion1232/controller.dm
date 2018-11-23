/obj/machinery/computer/hive_controller
	name = "Hivelink Communication Console"
	desc = "Complex machine, specially created to control specific hive."
	icon = 'code/WorkInProgress/polion1232/polionresearch.dmi'
	icon_state = "r_on"

	var/signature = XENO_HIVE_CORRUPTED
	use_power = 1
	idle_power_usage = 30
	active_power_usage = 2500
	var/screen = 1.0

//		For hive_orders
	var/high_command_orders = "NO KING-FATHER ORDERS GIVEN"
	var/command_orders = "NO FATHER ORDERS GIVEN"
	var/WO_orders = "NO WATCHER ORDERS GIVEN"
	var/full_orders = ""

	req_access = list(ACCESS_MARINE_BRIDGE)

/obj/machinery/computer/hive_controller/New()
	..()
	component_parts = list()
	component_parts += new /obj/item/circuitboard/machine/hive_controller(src)
	component_parts += new /obj/item/stock_parts/scanning_module
	component_parts += new /obj/item/stock_parts/scanning_module
	var/datum/hive_status/hive
	if(signature && signature <= hive_datum.len)
		hive = hive_datum[signature]
		hive.console_link = src
		full_orders = high_command_orders + "<BR>" + command_orders + "<BR>" + WO_orders

/obj/machinery/computer/hive_controller/Topic(href, href_list)
	if(..())
		return

	add_fingerprint(usr)

	usr.set_interaction(src)
	if(href_list["slashing"])
		var/datum/hive_status/hive
		if(signature && signature <= hive_datum.len)
			hive = hive_datum[signature]
		switch(href_list["slashing"])
			if("allow")
				hive.slashing_allowed = 1
			if("restrict")
				hive.slashing_allowed = 2
			if("forbid")
				hive.slashing_allowed = 0
		updateUsrDialog()

	else if(href_list["orders"])
		var/sender = "King-Father"
		switch(href_list["orders"])
			if("Staff Officer")
				sender = "Father"
			if("Chief MP")
				sender = "Watcher"

		var/txt = copytext(sanitize(input("Set the hive's orders to what? Leave blank to clear it.", "Hive Orders", null) as text), 1, MAX_MESSAGE_LEN)
		if(txt)
			if(sender == "Father")
				command_orders = "Order from [sender]: " + txt
			else if(sender == "Watcher")
				WO_orders = "Order from [sender]: " + txt
			else
				high_command_orders = "Order from [sender]: " + txt
			full_orders = high_command_orders + "<BR>" + command_orders + "<BR>" + WO_orders
			xeno_message("<B>[sender] have given a new order. Check Status panel for details.</B>",3,signature)
			hive_datum[signature].hive_orders = fix_rus_stats(full_orders)
		updateUsrDialog()

/obj/machinery/computer/hive_controller/attack_hand(mob/user as mob)
	if(stat & (BROKEN|NOPOWER))
		return

	if(!(src.allowed(usr) || emagged))
		to_chat(usr, "Unauthorized Access.")
		return

	user.set_interaction(src)
	var/dat = ""

	var/mob/living/carbon/human/officer
	if(ishuman(user))
		officer = user
	else
		dat += "CONSOLE BUGGED VIA RECIEVING ASSIGMENT"
		user << browse("<TITLE>USCM Almayer Medical and Research Division</TITLE><HR>[dat]", "window=rdconsole;size=575x400")
		onclose(user, "rdconsole")
		return
	var/assigment = officer.get_assignment()

	dat += "<center>Main Hivelink Communication Console</center><HR>"
	dat += "Hive codename - \"Corrupted\"</center><BR><BR>"
	dat += "Almayer High Command (CO,XO) codename: \"King-Father\".<BR>"
	dat += "Almayer Staff Officers codename: \"Father\".<BR>"
	dat += "Chief Military Police codename: \"Watcher\".<BR><BR>"
	dat += "WARNING! Be advised, if Almayer High Command or Warrant Officer didn't assigned you to XenoOverwatch, using this console is forbidden.<BR>"

	var/datum/hive_status/hive
	if(signature && signature <= hive_datum.len)
		hive = hive_datum[signature]
	else
		dat += "CONSOLE BUGGED"
		user << browse("<TITLE>USCM Almayer Medical and Research Division</TITLE><HR>[dat]", "window=rdconsole;size=575x400")
		onclose(user, "rdconsole")
		return

	dat += "<HR>"

	dat += "Command Sub-Unit status: "
	if(hive.living_xeno_queen)
		dat += "Active."
	else
		dat += "NOT FOUND."

	dat += "<HR>"

	dat += "Attacking human-like targets currently "
	switch(hive.slashing_allowed)
		if(1)
			dat += "allowed."
			dat += " Allow | <A href='?src=\ref[src];slashing=restrict'>Restrict</A> | <A href='?src=\ref[src];slashing=forbid'>Forbid</A>.<BR>"
		if(2)
			dat += "restricted to less damage."
			dat += " <A href='?src=\ref[src];slashing=allow'>Allow</A> | Restrict | <A href='?src=\ref[src];slashing=forbid'>Forbid</A>.<BR>"
		if(0)
			dat += "forbidden."
			dat += " <A href='?src=\ref[src];slashing=allow'>Allow</A> | <A href='?src=\ref[src];slashing=restrict'>Restrict</A> | Forbid.<BR>"

	dat += "<HR>"

	dat += "Hive Orders:<BR>"
	dat += full_orders
	dat += "<BR><A href='?src=\ref[src];orders=[assigment]'>Change Orders</A>.<BR>"

	dat += "<HR>"

	dat += "Evolution status: "
	if(!hive.living_xeno_queen)
		dat += "Evolution Halted - No command sub-unit.<BR>"
	else if(!hive.living_xeno_queen.ovipositor)
		dat += "Evolution Halted - Command sub-unit is not in oviposition.<BR>"
	else
		dat += "Evolution for all non-command sub-units active.<BR>"

	user << browse("<TITLE>USCM Almayer Medical and Research Division</TITLE><HR>[dat]", "window=hconsole;size=675x500")
	onclose(user, "hconsole")