// ============================================================
// BASIC TERRAIN TILES
// ============================================================

// Water
#define TILE_EMPTY             0
#define TILE_OCEAN             1   // Open ocean
#define TILE_RIVER             2   // Moving/shallow river water
#define TILE_STILLWATER        3   // Lakes, ponds, etc.

// Coastal
#define TILE_BEACH             10  // Sandy beach / shoreline

#define TILE_BEACH_LIGHT        10
#define TILE_BEACH_MID          11
#define TILE_BEACH_DENSE        12

#define TILE_DARKBEACH_LIGHT    13
#define TILE_DARKBEACH_MID      14
#define TILE_DARKBEACH_DENSE    15

// Basic land
#define TILE_GRASS             20  // Standard grass
#define TILE_CLIFF             21  // Rocky cliff face / elevated edge
#define TILE_ROCKY             22  // General rocky terrain

// Snow / cold
#define TILE_SNOW              30  // Snow-covered ground

// Volcanic
#define TILE_LAVA              40  // Lava

// Tall grass
#define TILE_TALLGRASS         50  // Normal tall grass
#define TILE_TALLGRASS_SAVANNAH 51 // Savannah tall grass
#define TILE_TALLGRASS_SNOWY   52  // Snowy/cold tall grass
#define TILE_TALLGRASS_VOLCANO 53  // Volcanic tall grass
#define TILE_TALLGRASS_GRAVEYARD 54 // Graveyard tall grass

// Arid
#define TILE_DESERT            60  // Sand / desert ground

// ============================================================
// MAJOR SURFACE BIOMES
// ============================================================

#define BIOME_PRAIRIE          1   // Open grassland / plains
#define BIOME_FOREST           2   // Standard forest
#define BIOME_DARK_FOREST      3   // Dense, darker forest
#define BIOME_ANCIENT_FOREST   4   // Old-growth / unusual forest

#define BIOME_TROPICAL_JUNGLE  5   // Dense tropical vegetation
#define BIOME_SAVANNA          6   // Open, warm grassland
#define BIOME_DESERT           7   // Sandy/arid region
#define BIOME_BADLANDS         8   // Rocky desert / cliffs

#define BIOME_TUNDRA           9   // Cold/snowy region
#define BIOME_MOUNTAIN         10  // Mountainous terrain
#define BIOME_VOLCANO          11  // Active volcanic region
#define BIOME_ASHLANDS         12  // Volcanic ash / barren terrain

#define BIOME_WETLANDS         13  // Marsh / swamp
#define BIOME_BEACH            14  // Coastal region
#define BIOME_OCEAN            15  // Ocean

// ============================================================
// SPECIAL / LOCALIZED BIOMES
// ============================================================

#define BIOME_GRAVEYARD        20  // Small cemetery / haunted area
#define BIOME_RUINS            21  // Ancient ruins / archaeological site

#define BIOME_RIVER            22  // River system
#define BIOME_LAKE             23  // Inland lake

#define BIOME_FROZEN_LAKE      24  // Frozen tundra lake

// ============================================================
// UNDERGROUND / ALTERNATE BIOMES
// ============================================================

#define BIOME_CAVE             30  // General cave
#define BIOME_MINE             31  // Mine / underground excavation

#define BIOME_ICE_CAVE         32  // Frozen/icy cave
#define BIOME_DRAGON_CAVE      33  // Large/deep cavern
#define BIOME_LAVA_CAVE        34  // Underground volcanic cave
#define BIOME_WATER_CAVE       35  // Flooded / aquatic cave

mob/verb/TestMap()
	if(can_move==FALSE) return
	FreezeMovement()
	world.Generator()
	UnfreezeMovement()

world/proc/Generator()

	// ========================================================
	// GENERATION STAGES
	// ========================================================
	world << "Generating landmass..." // use these to update a bar later.
	var/list/landmap = GenerateLandmass()

	var/list/biomemap// = GenerateBiomes(landmap)

	var/list/rivermap// = GenerateRivers(landmap, biomemap)

	var/list/featuremap// = GenerateFeatures(landmap, biomemap, rivermap)

	var/list/terrainmap// = GenerateTerrain(
	//	landmap,
	//	biomemap,
	//	rivermap,
	//	featuremap
	//)

	// ========================================================
	// FINAL MAP CREATION
	// ========================================================

	world << "Committing final map." // use these to update a bar later.
	CommitMap(
		landmap,
		biomemap,
		rivermap,
		featuremap,
		terrainmap
	)

// ============================================================
// LANDMASS GENERATION
// ============================================================
//
// Generates an island using overlapping filled circles.
//
// Process:
//
//     1. Fill entire map with ocean.
//
//     2. Create one large grass circle near the map center.
//        The circle is approximately 10% of total map area.
//
//     3. Around that circle:
//          - Get 8 evenly distributed edge points.
//          - Get 8 random edge points.
//          - Combine them without duplicates.
//          - Randomly choose up to 12.
//          - Place smaller grass circles at those points.
//
//     4. Repeat the process using the newly-created circles.
//        Each round:
//          - uses smaller circles
//          - uses fewer candidate edge points
//          - produces additional irregular growth
//
// ============================================================

world/proc/GenerateLandmass()

	var/list/landmap = list()


	// ========================================================
	// CREATE OCEAN
	// ========================================================

	for(var/x = 1, x <= world.maxx, x++)
		for(var/y = 1, y <= world.maxy, y++)
			MapSet(
				landmap,
				x,
				y,
				TILE_OCEAN
			)


	// ========================================================
	// CALCULATE INITIAL LANDMASS SIZE
	// ========================================================
	//
	// Circle area:
	//
	//     A = PI * r^2
	//
	// We want the initial circle to cover approximately 10%
	// of the total map.
	//
	// ========================================================

	var/map_area = world.maxx * world.maxy
	var/target_area = map_area * 0.10

	var/base_radius = round(
		sqrt(target_area / 3.14159)
	)

	// Keep at least a little ocean around the map edges.

	var/max_radius = round(
		min(world.maxx, world.maxy) * 0.40
	)

	base_radius = min(
		base_radius,
		max_radius
	)

	base_radius = max(
		base_radius,
		4
	)


	// ========================================================
	// INITIAL CIRCLE POSITION
	// ========================================================
	//
	// Start close to the center, but allow a little variation
	// so every generated island does not have the exact same
	// center of mass.
	//
	// ========================================================

	var/center_x = round(world.maxx / 2)
	var/center_y = round(world.maxy / 2)

	var/center_jitter = max(
		1,
		round(base_radius * 0.15)
	)

	center_x += rand(
		-center_jitter,
		center_jitter
	)

	center_y += rand(
		-center_jitter,
		center_jitter
	)


	// ========================================================
	// DRAW INITIAL CIRCLE
	// ========================================================

	DrawFilledCircle(
		landmap,
		center_x,
		center_y,
		base_radius,
		TILE_GRASS
	)


	// ========================================================
	// ACTIVE CIRCLES
	// ========================================================
	//
	// Each circle is stored as:
	//
	//     list(
	//         "x" = center_x,
	//         "y" = center_y,
	//         "radius" = radius
	//     )
	//
	// Only circles from the previous round are expanded.
	//
	// ========================================================

	var/list/active_circles = list()

	active_circles += list(
		list(
			"x" = center_x,
			"y" = center_y,
			"radius" = base_radius
		)
	)


	// ========================================================
	// GENERATION ROUNDS
	// ========================================================
	//
	// Round 1:
	//     8 even + 8 random
	//     choose 12
	//
	// Round 2:
	//     4 even + 4 random
	//     choose 5
	//
	// Round 3:
	//     2 even + 2 random
	//     choose 2
	//
	// ========================================================

	var/generation_rounds = rand(
		2,
		3
	)

	for(var/round = 1, round <= generation_rounds, round++)

		var/even_points
		var/random_points
		var/points_to_use

		if(round == 1)

			even_points = 8
			random_points = 8
			points_to_use = 12

		else if(round == 2)

			even_points = 4
			random_points = 4
			points_to_use = 5

		else

			even_points = 2
			random_points = 2
			points_to_use = 2


		var/list/next_circles = list()


		// ----------------------------------------------------
		// EXPAND EACH ACTIVE CIRCLE
		// ----------------------------------------------------

		for(var/list/circle in active_circles)

			var/circle_x = circle["x"]
			var/circle_y = circle["y"]
			var/circle_radius = circle["radius"]


			// ------------------------------------------------
			// GET EDGE POINTS
			// ------------------------------------------------

			var/list/even = GetEvenPointsAroundCircle(
				circle_x,
				circle_y,
				circle_radius,
				even_points
			)

			var/list/random = GetPointsAroundCircle(
				circle_x,
				circle_y,
				circle_radius,
				random_points
			)

			var/list/candidates = CombineUniquePointLists(
				even,
				random
			)


			// ------------------------------------------------
			// RANDOMLY SELECT FROM THE COMBINED POINTS
			// ------------------------------------------------

			var/list/selected = list()

			var/select_count = min(
				points_to_use,
				candidates.len
			)

			for(var/i = 1, i <= select_count, i++)

				if(candidates.len <= 0)
					break

				var/index = rand(
					1,
					candidates.len
				)

				var/list/P = candidates[index]

				selected += list(
					list(
						P[1],
						P[2]
					)
				)

				candidates.Cut(
					index,
					index + 1
				)


			// ------------------------------------------------
			// CREATE CHILD CIRCLES
			// ------------------------------------------------

			for(var/list/P in selected)

				var/child_x = P[1]
				var/child_y = P[2]

				var/min_child_radius = round(
					circle_radius * 0.40
				)

				var/max_child_radius = round(
					circle_radius * 0.65
				)

				min_child_radius = max(
					min_child_radius,
					2
				)

				max_child_radius = max(
					max_child_radius,
					min_child_radius
				)

				var/child_radius = rand(
					min_child_radius,
					max_child_radius
				)


				// --------------------------------------------
				// KEEP CIRCLE INSIDE WORLD
				// --------------------------------------------

				if(child_x - child_radius < 1)
					continue

				if(child_x + child_radius > world.maxx)
					continue

				if(child_y - child_radius < 1)
					continue

				if(child_y + child_radius > world.maxy)
					continue


				// --------------------------------------------
				// DRAW CHILD
				// --------------------------------------------

				DrawFilledCircle(
					landmap,
					child_x,
					child_y,
					child_radius,
					TILE_GRASS
				)


				// --------------------------------------------
				// STORE FOR NEXT ROUND
				// --------------------------------------------

				next_circles += list(
					list(
						"x" = child_x,
						"y" = child_y,
						"radius" = child_radius
					)
				)


		// ----------------------------------------------------
		// NEXT GENERATION
		// ----------------------------------------------------

		active_circles = next_circles

		if(active_circles.len <= 0)
			break

	// ========================================================
	// LONG LAND SPINES / PENINSULAS
	// ========================================================
	//
	// Adds several long curved stretches of land extending
	// outward from the main island body.
	//
	// Spines are shortened automatically if their endpoint
	// would get too close to the map edge.
	//
	// ========================================================

	var/spine_count = rand(2, 4)

	var/list/spine_starts = GetEvenPointsAroundCircle(
		center_x,
		center_y,
		base_radius,
		spine_count
	)

	for(var/list/P in spine_starts)

		var/start_x = P[1]
		var/start_y = P[2]


		// ----------------------------------------------------
		// DIRECTION AWAY FROM CENTER
		// ----------------------------------------------------

		var/dx = start_x - center_x
		var/dy = start_y - center_y

		var/distance = sqrt((dx * dx) + (dy * dy))

		if(distance <= 0)
			continue

		var/direction_x = dx / distance
		var/direction_y = dy / distance


		// ----------------------------------------------------
		// PENINSULA LENGTH
		// ----------------------------------------------------

		var/min_spine_length = round(
			base_radius * 1.0
		)

		var/max_spine_length = round(
			base_radius * 2.0
		)

		var/spine_length = rand(
			min_spine_length,
			max_spine_length
		)


		// ----------------------------------------------------
		// END CAP SIZE
		// ----------------------------------------------------
		//
		// Calculate this before the endpoint so we know how
		// much room the final circle requires.
		//
		// ----------------------------------------------------

		var/min_end_radius = round(
			base_radius * 0.25
		)

		var/max_end_radius = round(
			base_radius * 0.45
		)

		min_end_radius = max(
			min_end_radius,
			3
		)

		max_end_radius = max(
			max_end_radius,
			min_end_radius
		)

		var/end_radius = rand(
			min_end_radius,
			max_end_radius
		)


		// ----------------------------------------------------
		// SAFE MAP MARGIN
		// ----------------------------------------------------
		//
		// Keep enough space around the endpoint that the
		// entire end-cap circle remains inside the world.
		//
		// ----------------------------------------------------

		var/safe_margin = end_radius + 3


		// ----------------------------------------------------
		// FIND SAFE END POINT
		// ----------------------------------------------------
		//
		// Start with the desired spine length.
		//
		// If that endpoint is too close to the world edge,
		// shorten the spine until it fits.
		//
		// ----------------------------------------------------

		var/end_x = round(start_x + (direction_x * spine_length))

		var/end_y = round(start_y + (direction_y * spine_length))


		while(spine_length > 4 && (end_x < safe_margin || end_x > world.maxx - safe_margin || end_y < safe_margin || end_y > world.maxy - safe_margin))

			spine_length--

			end_x = round(start_x + (direction_x * spine_length))

			end_y = round(start_y + (direction_y * spine_length))


		// ----------------------------------------------------
		// FINAL SAFETY CHECK
		// ----------------------------------------------------
		//
		// If even a very short spine cannot fit safely,
		// abandon this branch.
		//
		// ----------------------------------------------------

		if(end_x < safe_margin || end_x > world.maxx - safe_margin || end_y < safe_margin || end_y > world.maxy - safe_margin)
			continue


		// ----------------------------------------------------
		// CONTROL POINT
		// ----------------------------------------------------
		//
		// Start with the midpoint between start and end.
		//
		// Then move the control point sideways relative to the
		// outward direction so the peninsula bends.
		//
		// ----------------------------------------------------

		var/control_x = round(
			(start_x + end_x) / 2
		)

		var/control_y = round(
			(start_y + end_y) / 2
		)

		var/perpendicular_x = -direction_y
		var/perpendicular_y = direction_x

		var/max_sideways = round(
			base_radius * 0.50
		)

		var/sideways = rand(
			-max_sideways,
			max_sideways
		)

		control_x += round(
			perpendicular_x * sideways
		)

		control_y += round(
			perpendicular_y * sideways
		)


		// ----------------------------------------------------
		// CLAMP CONTROL POINT
		// ----------------------------------------------------
		//
		// Even if the endpoint is safe, a large curve could
		// otherwise bow outside the map.
		//
		// ----------------------------------------------------

		control_x = max(
			safe_margin,
			min(
				world.maxx - safe_margin,
				control_x
			)
		)

		control_y = max(
			safe_margin,
			min(
				world.maxy - safe_margin,
				control_y
			)
		)


		// ----------------------------------------------------
		// SPINE WIDTH
		// ----------------------------------------------------

		var/min_spine_width = round(
			base_radius * 0.25
		)

		var/max_spine_width = round(
			base_radius * 0.45
		)

		min_spine_width = max(
			min_spine_width,
			3
		)

		max_spine_width = max(
			max_spine_width,
			min_spine_width
		)

		var/spine_width = rand(
			min_spine_width,
			max_spine_width
		)


		// ----------------------------------------------------
		// DRAW LAND SPINE
		// ----------------------------------------------------

		DrawThickCurve(
			landmap,
			start_x,
			start_y,
			control_x,
			control_y,
			end_x,
			end_y,
			spine_width,
			TILE_GRASS
		)


		// ----------------------------------------------------
		// END CAP
		// ----------------------------------------------------

		DrawFilledCircle(
			landmap,
			end_x,
			end_y,
			end_radius,
			TILE_GRASS
		)

		world << "3 Coastline passes running." // use these to update a bar later.
		RoughenCoastline(landmap,3,30,20)
		world << "Adding beaches." // use these to update a bar later.
		AddBeaches(landmap,3,4,20)
		world << "Cleaning up isolated shoreline pieces." // use these to update a bar later.
		CleanupIsolatedShorelineWater(landmap)
	return landmap

// ============================================================
// MAP COMMIT
// ============================================================
//
// Converts generated map data into actual BYOND turfs.
//
// At the moment, landmass generation only produces:
//
//     TILE_OCEAN
//     TILE_GRASS
//
// Additional biome / river / feature / terrain layers can be
// integrated here later as those generation stages are built.
//
// ============================================================

world/proc/CommitMap(
	var/list/landmap,
	var/list/biomemap,
	var/list/rivermap,
	var/list/featuremap,
	var/list/terrainmap
)
	if(!landmap)
		return


	for(var/x = 1, x <= world.maxx, x++)
		for(var/y = 1, y <= world.maxy, y++)

			var/tile = MapGet(
				landmap,
				x,
				y
			)

			var/turf/current_turf = locate(
				x,
				y,
				1
			)

			if(!current_turf)
				continue


			// =================================================
			// OCEAN
			// =================================================

			if(tile == TILE_OCEAN)

				if(!istype(current_turf, /turf/Water))
					new /turf/Water(current_turf)


			// =================================================
			// LAND
			// =================================================

			else if(tile == TILE_GRASS)

				if(!istype(current_turf, /turf/ShortGrass))
					new /turf/ShortGrass(current_turf)

			else if(tile == TILE_BEACH_LIGHT)
				if(!istype(current_turf, /turf/WhiteSandLight))
					new /turf/WhiteSandLight(current_turf)

			else if(tile == TILE_BEACH_MID)
				if(!istype(current_turf, /turf/WhiteSandMid))
					new /turf/WhiteSandMid(current_turf)

			else if(tile == TILE_BEACH_DENSE)
				if(!istype(current_turf, /turf/WhiteSandDense))
					new /turf/WhiteSandDense(current_turf)


			else if(tile == TILE_DARKBEACH_LIGHT)
				if(!istype(current_turf, /turf/DarkSandLight))
					new /turf/DarkSandLight(current_turf)

			else if(tile == TILE_DARKBEACH_MID)
				if(!istype(current_turf, /turf/DarkSandMid))
					new /turf/DarkSandMid(current_turf)

			else if(tile == TILE_DARKBEACH_DENSE)
				if(!istype(current_turf, /turf/DarkSandDense))
					new /turf/DarkSandDense(current_turf)


// ============================================================
// ROUGHEN COASTLINE
// ============================================================
//
// Adds irregularity to the edge of a generated landmass.
//
// The proc performs several passes over tiles near the
// coastline.
//
// Land tiles may be eroded into ocean.
// Ocean tiles may grow into land.
//
// Changes are collected first and applied after each pass so
// modifying one tile does not immediately affect neighboring
// calculations during the same pass.
//
// passes:
//     Number of roughening passes.
//
// erosion_chance:
//     Chance for exposed land tiles to become ocean.
//
// growth_chance:
//     Chance for ocean tiles near substantial land to become
//     grass.
//
// ============================================================

world/proc/RoughenCoastline(
	var/list/landmap,
	var/passes = 3,
	var/erosion_chance = 30,
	var/growth_chance = 20
)
	set background = 1 // this code can take a while.
	if(!landmap)
		return

	for(var/pass = 1, pass <= passes, pass++)

		var/list/to_ocean = list()
		var/list/to_land = list()


		for(var/x = 2, x < world.maxx, x++)
			for(var/y = 2, y < world.maxy, y++)

				var/current_tile = MapGet(
					landmap,
					x,
					y
				)

				var/land_neighbours = 0


				// --------------------------------------------
				// COUNT SURROUNDING LAND
				// --------------------------------------------

				for(var/check_x = x - 1, check_x <= x + 1, check_x++)
					for(var/check_y = y - 1, check_y <= y + 1, check_y++)

						if(check_x == x && check_y == y)
							continue

						if(MapGet(landmap, check_x, check_y) == TILE_GRASS)
							land_neighbours++


				// --------------------------------------------
				// ERODE EXPOSED LAND
				// --------------------------------------------
				//
				// Interior land has many land neighbours and
				// is left alone.
				//
				// Coastline tiles with only a few surrounding
				// land tiles may be removed.
				//
				// --------------------------------------------

				if(current_tile == TILE_GRASS)

					if(land_neighbours <= 3 && prob(erosion_chance))

						to_ocean += list(
							list(x, y)
						)


				// --------------------------------------------
				// GROW COAST OUTWARD
				// --------------------------------------------
				//
				// Ocean tiles with several adjacent land tiles
				// may become land.
				//
				// Requiring multiple land neighbours prevents
				// random isolated grass pixels appearing in
				// the ocean.
				//
				// --------------------------------------------

				else if(current_tile == TILE_OCEAN)

					if(land_neighbours >= 3 && land_neighbours <= 6 && prob(growth_chance))

						to_land += list(
							list(x, y)
						)


		// ====================================================
		// APPLY CHANGES
		// ====================================================

		for(var/list/P in to_ocean)

			MapSet(
				landmap,
				P[1],
				P[2],
				TILE_OCEAN
			)


		for(var/list/P in to_land)

			MapSet(
				landmap,
				P[1],
				P[2],
				TILE_GRASS
			)

// ============================================================
// ADD BEACHES
// ============================================================
//
// Converts grass along the ocean coastline into beach.
//
// Beaches are generally made from the light sand variant.
//
// Occasionally, dense sand patches are created inside the
// beach. Tiles around those dense patches are converted to
// mid-density sand, creating a simple gradient:
//
//     LIGHT -> MID -> DENSE
//
// Individual beach areas may use either white or dark sand.
//
// beach_depth:
//     Maximum number of tiles the beach may extend inland.
//
// dense_chance:
//     Chance for an eligible beach tile to become the center
//     of a dense-sand patch.
//
// dark_beach_chance:
//     Chance for a beach region to use dark sand.
//
// ============================================================

world/proc/AddBeaches(
	var/list/landmap,
	var/beach_depth = 3,
	var/dense_chance = 4,
	var/dark_beach_chance = 20
)
	if(!landmap)
		return


	// ========================================================
	// FIND COASTLINE
	// ========================================================
	//
	// Start with grass tiles directly touching ocean.
	//
	// ========================================================

	var/list/current_layer = list()
	var/list/beach_tiles = list()

	for(var/x = 2, x < world.maxx, x++)
		for(var/y = 2, y < world.maxy, y++)

			if(MapGet(landmap, x, y) != TILE_GRASS)
				continue

			var/touches_ocean = FALSE

			if(MapGet(landmap, x + 1, y) == TILE_OCEAN)
				touches_ocean = TRUE

			if(MapGet(landmap, x - 1, y) == TILE_OCEAN)
				touches_ocean = TRUE

			if(MapGet(landmap, x, y + 1) == TILE_OCEAN)
				touches_ocean = TRUE

			if(MapGet(landmap, x, y - 1) == TILE_OCEAN)
				touches_ocean = TRUE

			if(touches_ocean)

				var/key = MapKey(x, y)

				beach_tiles[key] = 1

				current_layer += list(
					list(x, y)
				)


	// ========================================================
	// GROW BEACH INLAND
	// ========================================================
	//
	// Each pass expands one tile farther into existing grass.
	//
	// The irregular coastline itself gives us a naturally
	// irregular beach shape.
	//
	// ========================================================

	for(var/depth = 2, depth <= beach_depth, depth++)

		var/list/next_layer = list()

		for(var/list/P in current_layer)

			var/x = P[1]
			var/y = P[2]

			var/list/neighbours = MapNeighbours(
				x,
				y
			)

			for(var/list/N in neighbours)

				var/nx = N[1]
				var/ny = N[2]

				if(MapGet(landmap, nx, ny) != TILE_GRASS)
					continue

				var/key = MapKey(nx, ny)

				if(key in beach_tiles)
					continue


				// Beaches should become less consistent the
				// farther inland they grow.

				var/grow_chance = 100

				if(depth == 2)
					grow_chance = 75

				else if(depth >= 3)
					grow_chance = 45


				if(!prob(grow_chance))
					continue


				beach_tiles[key] = depth

				next_layer += list(
					list(nx, ny)
				)


		current_layer = next_layer

		if(current_layer.len <= 0)
			break


	// ========================================================
	// ASSIGN BASE BEACH TYPE
	// ========================================================
	//
	// Most beach tiles begin as light sand.
	//
	// We currently choose dark-vs-white individually with a
	// low probability. This can later be upgraded to choose
	// entire beach regions if desired.
	//
	// ========================================================

	var/list/dark_tiles = list()

	for(var/key in beach_tiles)

		var/list/coords = splittext(
			key,
			","
		)

		var/x = text2num(coords[1])
		var/y = text2num(coords[2])

		if(prob(dark_beach_chance))

			MapSet(
				landmap,
				x,
				y,
				TILE_DARKBEACH_LIGHT
			)

			dark_tiles[key] = TRUE

		else

			MapSet(
				landmap,
				x,
				y,
				TILE_BEACH_LIGHT
			)


	// ========================================================
	// CREATE DENSE PATCHES
	// ========================================================
	//
	// Dense tiles are rare.
	//
	// Any beach tiles directly surrounding a dense tile become
	// mid-density sand, producing:
	//
	//          light
	//       light mid
	//     light mid dense
	//
	// ========================================================

	var/list/dense_points = list()

	for(var/key in beach_tiles)

		if(!prob(dense_chance))
			continue

		var/list/coords = splittext(
			key,
			","
		)

		var/x = text2num(coords[1])
		var/y = text2num(coords[2])

		dense_points += list(
			list(x, y)
		)


	// ========================================================
	// APPLY DENSE CENTERS
	// ========================================================

	for(var/list/P in dense_points)

		var/x = P[1]
		var/y = P[2]

		var/current_tile = MapGet(
			landmap,
			x,
			y
		)

		var/use_dark = FALSE

		if(current_tile == TILE_DARKBEACH_LIGHT)
			use_dark = TRUE

		if(current_tile == TILE_DARKBEACH_MID)
			use_dark = TRUE


		if(use_dark)

			MapSet(
				landmap,
				x,
				y,
				TILE_DARKBEACH_DENSE
			)

		else

			MapSet(
				landmap,
				x,
				y,
				TILE_BEACH_DENSE
			)


		// ----------------------------------------------------
		// MID-DENSITY RING
		// ----------------------------------------------------

		for(var/check_x = x - 1, check_x <= x + 1, check_x++)
			for(var/check_y = y - 1, check_y <= y + 1, check_y++)

				if(check_x == x && check_y == y)
					continue

				var/neighbour_tile = MapGet(
					landmap,
					check_x,
					check_y
				)

				if(use_dark && neighbour_tile == TILE_DARKBEACH_LIGHT)

					MapSet(
						landmap,
						check_x,
						check_y,
						TILE_DARKBEACH_MID
					)


				else if(!use_dark && neighbour_tile == TILE_BEACH_LIGHT)

					MapSet(
						landmap,
						check_x,
						check_y,
						TILE_BEACH_MID
					)

// ============================================================
// IS BEACH TILE
// ============================================================
//
// Returns TRUE if the supplied tile value is one of the
// generated beach variants.
//
// ============================================================

world/proc/IsBeachTile(var/tile)

	if(tile == TILE_BEACH_LIGHT)
		return TRUE

	if(tile == TILE_BEACH_MID)
		return TRUE

	if(tile == TILE_BEACH_DENSE)
		return TRUE

	if(tile == TILE_DARKBEACH_LIGHT)
		return TRUE

	if(tile == TILE_DARKBEACH_MID)
		return TRUE

	if(tile == TILE_DARKBEACH_DENSE)
		return TRUE

	return FALSE


// ============================================================
// CLEANUP ISOLATED SHORELINE WATER
// ============================================================
//
// Removes single isolated ocean tiles left inside generated
// beaches.
//
// An ocean tile is filled when:
//
//     - it has no cardinal ocean neighbours
//     - it is surrounded mostly by beach / land
//
// The replacement uses the most common neighbouring beach
// variant so the cleanup blends into the surrounding shore.
//
// ============================================================

world/proc/CleanupIsolatedShorelineWater(var/list/landmap)

	if(!landmap)
		return

	var/list/to_fill = list()


	// ========================================================
	// FIND ISOLATED OCEAN TILES
	// ========================================================

	for(var/x = 2, x < world.maxx, x++)
		for(var/y = 2, y < world.maxy, y++)

			if(MapGet(landmap, x, y) != TILE_OCEAN)
				continue


			// ------------------------------------------------
			// CARDINAL OCEAN NEIGHBOURS
			// ------------------------------------------------

			var/cardinal_ocean = 0

			if(MapGet(landmap, x + 1, y) == TILE_OCEAN)
				cardinal_ocean++

			if(MapGet(landmap, x - 1, y) == TILE_OCEAN)
				cardinal_ocean++

			if(MapGet(landmap, x, y + 1) == TILE_OCEAN)
				cardinal_ocean++

			if(MapGet(landmap, x, y - 1) == TILE_OCEAN)
				cardinal_ocean++


			// If it connects directly to more ocean, leave it
			// alone as part of the actual shoreline.

			if(cardinal_ocean > 0)
				continue


			// ------------------------------------------------
			// CHECK SURROUNDING LAND / BEACH
			// ------------------------------------------------

			var/beach_neighbours = 0
			var/land_neighbours = 0

			for(var/check_x = x - 1, check_x <= x + 1, check_x++)
				for(var/check_y = y - 1, check_y <= y + 1, check_y++)

					if(check_x == x && check_y == y)
						continue

					var/near_tile = MapGet(
						landmap,
						check_x,
						check_y
					)

					if(IsBeachTile(near_tile))
						beach_neighbours++

					else if(near_tile == TILE_GRASS)
						land_neighbours++


			if(beach_neighbours + land_neighbours < 5)
				continue


			// ------------------------------------------------
			// FIND MOST COMMON NEARBY BEACH VARIANT
			// ------------------------------------------------

			var/white_light = 0
			var/white_mid = 0
			var/white_dense = 0

			var/dark_light = 0
			var/dark_mid = 0
			var/dark_dense = 0

			for(var/check_x = x - 1, check_x <= x + 1, check_x++)
				for(var/check_y = y - 1, check_y <= y + 1, check_y++)

					if(check_x == x && check_y == y)
						continue

					var/near_tile = MapGet(
						landmap,
						check_x,
						check_y
					)

					if(near_tile == TILE_BEACH_LIGHT)
						white_light++

					else if(near_tile == TILE_BEACH_MID)
						white_mid++

					else if(near_tile == TILE_BEACH_DENSE)
						white_dense++

					else if(near_tile == TILE_DARKBEACH_LIGHT)
						dark_light++

					else if(near_tile == TILE_DARKBEACH_MID)
						dark_mid++

					else if(near_tile == TILE_DARKBEACH_DENSE)
						dark_dense++


			var/replacement_tile = TILE_BEACH_LIGHT
			var/best_count = white_light

			if(white_mid > best_count)
				best_count = white_mid
				replacement_tile = TILE_BEACH_MID

			if(white_dense > best_count)
				best_count = white_dense
				replacement_tile = TILE_BEACH_DENSE

			if(dark_light > best_count)
				best_count = dark_light
				replacement_tile = TILE_DARKBEACH_LIGHT

			if(dark_mid > best_count)
				best_count = dark_mid
				replacement_tile = TILE_DARKBEACH_MID

			if(dark_dense > best_count)
				replacement_tile = TILE_DARKBEACH_DENSE


			to_fill += list(
				list(
					x,
					y,
					replacement_tile
				)
			)


	// ========================================================
	// APPLY CLEANUP
	// ========================================================

	for(var/list/P in to_fill)

		MapSet(
			landmap,
			P[1],
			P[2],
			P[3]
		)
