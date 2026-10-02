obj/tree
	Tree1
		icon = 'TallBigTrees.dmi'
		icon_state = "2"

	ThinTree1
		icon = 'TallThinTrees.dmi'
		icon_state = "Tree_Dense"

	SmallTree1
		icon = 'TreeSmall.dmi'
		icon_state = "Round"

// ============================================================
// LEDGE
// ============================================================
//
// Ledges connect only to neighbouring ledges at the same
// elevation height.
//
// Sprite families:
//
//     Straights:
//         T B L R
//
//     Normal corners:
//         TL TR BL BR
//
//     Mini corners:
//         MTL MTR MBL MBR
//
//     Extended corners:
//         XTL XTR XBL XBR
//
// height:
//     Elevation level represented by this ledge.
//
// shape_hint:
//     Optional explicit state override.
//
// ============================================================

obj/ledge
	icon = 'Ledges.dmi'
	icon_state = "T"

	var/height = 1
	var/shape_hint = null


	// ========================================================
	// GET SAME-HEIGHT LEDGE
	// ========================================================

	proc/GetLedge(var/direction)

		var/turf/T = get_step(src, direction)

		if(!T)
			return null

		for(var/obj/ledge/L in T)

			if(L.height == height)
				return L

		return null


	proc/HasLedge(var/direction)

		return GetLedge(direction) != null


	// ========================================================
	// AUTO JOIN
	// ========================================================

	proc/AutoJoin()

		var/old_state = icon_state

		// Explicit visual state always wins.
		if(shape_hint)

			icon_state = shape_hint

			return icon_state != old_state


		var/N = HasLedge(NORTH)
		var/S = HasLedge(SOUTH)
		var/E = HasLedge(EAST)
		var/W = HasLedge(WEST)


		// ====================================================
		// NORMAL CORNERS
		// ====================================================

		if(S && E && !N && !W)
			icon_state = "TL"

		else if(S && W && !N && !E)
			icon_state = "TR"

		else if(N && E && !S && !W)
			icon_state = "BL"

		else if(N && W && !S && !E)
			icon_state = "BR"


		// ====================================================
		// HORIZONTAL STRAIGHT
		// ====================================================

		else if(E && W && !N && !S)

			var/obj/ledge/EL = GetLedge(EAST)
			var/obj/ledge/WL = GetLedge(WEST)

			var/use_top = FALSE
			var/use_bottom = FALSE

			if(WL && WL.icon_state in list("T", "TL", "TR", "MTL", "MTR", "XTL", "XTR"))
				use_top = TRUE

			if(WL && WL.icon_state in list("B", "BL", "BR", "MBL", "MBR", "XBL", "XBR"))
				use_bottom = TRUE

			if(EL && EL.icon_state in list("T", "TL", "TR", "MTL", "MTR", "XTL", "XTR"))
				use_top = TRUE

			if(EL && EL.icon_state in list("B", "BL", "BR", "MBL", "MBR", "XBL", "XBR"))
				use_bottom = TRUE


			if(use_top && !use_bottom)
				icon_state = "T"

			else if(use_bottom && !use_top)
				icon_state = "B"

			else if(use_top)
				icon_state = "T"

			else if(use_bottom)
				icon_state = "B"


		// ====================================================
		// VERTICAL STRAIGHT
		// ====================================================

		else if(N && S && !E && !W)

			var/obj/ledge/NL = GetLedge(NORTH)
			var/obj/ledge/SL = GetLedge(SOUTH)

			var/use_left = FALSE
			var/use_right = FALSE

			if(NL && NL.icon_state in list("L", "TL", "BL", "MTL", "MBL", "XTL", "XBL"))
				use_left = TRUE

			if(NL && NL.icon_state in list("R", "TR", "BR", "MTR", "MBR", "XTR", "XBR"))
				use_right = TRUE

			if(SL && SL.icon_state in list("L", "TL", "BL", "MTL", "MBL", "XTL", "XBL"))
				use_left = TRUE

			if(SL && SL.icon_state in list("R", "TR", "BR", "MTR", "MBR", "XTR", "XBR"))
				use_right = TRUE


			if(use_left && !use_right)
				icon_state = "L"

			else if(use_right && !use_left)
				icon_state = "R"

			else if(use_left)
				icon_state = "L"

			else if(use_right)
				icon_state = "R"


		return icon_state != old_state

// ============================================================
// AUTO JOIN ALL LEDGES
// ============================================================

world/proc/AutoJoinAllLedges()

	var/changed = TRUE
	var/pass = 0

	while(changed)

		changed = FALSE
		pass++

		for(var/obj/ledge/L in world)

			if(L.AutoJoin())
				changed = TRUE

		if(pass >= 100)
			break