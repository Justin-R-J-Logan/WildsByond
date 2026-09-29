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
// Auto-joining ledge object.
//
// Adjacency determines the shape of the ledge:
//
//     horizontal
//     vertical
//     corner
//
// Corner pieces establish which half of the tile the ledge
// occupies. Straight pieces inherit that alignment from their
// neighbours.
//
// Inner corners require an explicit inner_missing value because
// ledge adjacency alone cannot distinguish a convex corner from
// a concave corner.
//
// inner_missing may be:
//
//     NORTHWEST -> NTL
//     NORTHEAST -> NTR
//     SOUTHWEST -> NBL
//     SOUTHEAST -> NBR
//
// ============================================================

obj/ledge
	icon = 'Ledges.dmi'
	icon_state = "T"

	// Set this when generation knows this tile is an
	// inner/concave corner.
	var/inner_missing = 0


	// ========================================================
	// GET NEIGHBOUR LEDGE
	// ========================================================

	proc/GetNeighbourLedge(var/direction)

		var/turf/T = get_step(src, direction)

		if(!T)
			return null

		for(var/obj/ledge/L in T)
			return L

		return null


	// ========================================================
	// GET HORIZONTAL ALIGNMENT
	// ========================================================
	//
	// Returns NORTH if this ledge uses the upper half of the
	// tile, SOUTH if it uses the lower half, or 0 if unknown.
	//
	// ========================================================

	proc/GetHorizontalAlignment()

		switch(icon_state)

			if("T", "TL", "TR")
				return NORTH

			if("B", "BL", "BR")
				return SOUTH

		return 0


	// ========================================================
	// GET VERTICAL ALIGNMENT
	// ========================================================
	//
	// Returns WEST if this ledge uses the left half of the
	// tile, EAST if it uses the right half, or 0 if unknown.
	//
	// ========================================================

	proc/GetVerticalAlignment()

		switch(icon_state)

			if("L", "TL", "BL")
				return WEST

			if("R", "TR", "BR")
				return EAST

		return 0


	// ========================================================
	// AUTO JOIN
	// ========================================================

	proc/AutoJoin()

		var/obj/ledge/N = GetNeighbourLedge(NORTH)
		var/obj/ledge/S = GetNeighbourLedge(SOUTH)
		var/obj/ledge/E = GetNeighbourLedge(EAST)
		var/obj/ledge/W = GetNeighbourLedge(WEST)

		var/old_state = icon_state


		// ====================================================
		// INNER CORNERS
		// ====================================================
		//
		// These are explicitly marked because connectivity
		// alone cannot tell an inner corner from an outer one.
		//
		// ====================================================

		if(inner_missing)

			switch(inner_missing)

				if(NORTHWEST)
					icon_state = "NTL"

				if(NORTHEAST)
					icon_state = "NTR"

				if(SOUTHWEST)
					icon_state = "NBL"

				if(SOUTHEAST)
					icon_state = "NBR"

			return icon_state != old_state


		// ====================================================
		// OUTER CORNERS
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

			var/alignment = 0

			// Try the west neighbour first.

			if(W)
				alignment = W.GetHorizontalAlignment()


			// Then the east neighbour.

			if(!alignment && E)
				alignment = E.GetHorizontalAlignment()


			if(alignment == NORTH)
				icon_state = "T"

			else if(alignment == SOUTH)
				icon_state = "B"


		// ====================================================
		// VERTICAL STRAIGHT
		// ====================================================

		else if(N && S && !E && !W)

			var/alignment = 0

			// Try north first.

			if(N)
				alignment = N.GetVerticalAlignment()


			// Then south.

			if(!alignment && S)
				alignment = S.GetVerticalAlignment()


			if(alignment == WEST)
				icon_state = "L"

			else if(alignment == EAST)
				icon_state = "R"


		return icon_state != old_state

// ============================================================
// AUTO JOIN ALL LEDGES
// ============================================================
//
// Repeated passes allow straight-piece alignment to propagate
// from corners along long ledge runs.
//
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