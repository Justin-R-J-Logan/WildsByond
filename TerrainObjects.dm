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
// Ledges at different heights do NOT automatically connect.
//
// ============================================================

obj/ledge
	icon = 'Ledges.dmi'
	icon_state = "T"

	var/height = 1
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

	proc/AutoJoin()

		var/N  = HasLedge(NORTH)
		var/S  = HasLedge(SOUTH)
		var/E  = HasLedge(EAST)
		var/W  = HasLedge(WEST)

		var/NE = HasLedge(NORTHEAST)
		var/NW = HasLedge(NORTHWEST)
		var/SE = HasLedge(SOUTHEAST)
		var/SW = HasLedge(SOUTHWEST)

		var/old_state = icon_state