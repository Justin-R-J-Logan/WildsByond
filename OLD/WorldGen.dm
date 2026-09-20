// ============================================
// DEFINITIONS
// ============================================

#define TILE_OCEAN 0
#define TILE_LAND 1
#define TILE_CLIFF 2

#define MAP_XXS 128   // Testing size
#define MAP_XS 256
#define MAP_S 512
#define MAP_M 768
#define MAP_L 1024

#define BIOME_GRID_SIZE 8  // Coarse grid cell size
#define CLIFF_WIDTH_MIN 2
#define CLIFF_WIDTH_MAX 6

#define PI 3.14159265

// ============================================
// BIOME DEFINITIONS
// ============================================

// Edit this list to control which biomes can have volcanoes
var/list/VolcanoBiomes = list("ice", "forest_dark", "desert")

// Biome type constants
#define BIOME_OCEAN 0
#define BIOME_DESERT 1
#define BIOME_FOREST_LIGHT 2
#define BIOME_FOREST_DARK 3
#define BIOME_ICE 4

// Biome to turf mapping (used during commit)
var/list/BiomeToTurf = list(
    "desert" = "turf/Desert",
    "forest_light" = "turf/Grass",  // Light green
    "forest_dark" = "turf/Forest", // Dark green
    "ice" = "turf/Snow"            // White/snow
)

mob/verb/Gen2()
	world.Generate()

// ============================================
// MASTER GENERATION ENTRY
// ============================================

world/proc/Generate()
	var/world_size = GetNextMapSize()

	world.maxx = world_size
	world.maxy = world_size
	world.maxz = 1

	world << "Starting island generation... [world_size]x[world_size]"

	// Step 1: Generate island shape via fractal circles
	var/list/map_data = GenerateFractalIsland(world_size)

	world << "Island shape complete, applying biomes..."

	// Step 2: Apply biome grid overlay
	map_data = ApplyBiomeGrid(map_data, world_size)

	world << "Biomes applied, adding cliffs..."

	// Step 3: Add cliff borders between biomes
	map_data = AddCliffBorders(map_data, world_size)

	world << "Cliffs added, committing to map..."

	// Step 4: Commit to turfs
	CommitMapToTurfs(map_data, world_size)

	// Step 5: Place volcanoes
	PlaceVolcanoes(world_size)

	world << "Generation complete!"

world/proc/GetNextMapSize()
	return MAP_XXS  // 128×128 for testing

// ============================================
// FRACTAL ISLAND GENERATION
// ============================================

world/proc/GenerateFractalIsland(var/size)
	var/list/map = InitializeEmptyMap(size, size)

	// Determine how many primary circles based on map size
	var/num_primary_circles
	switch(size)
		if(128) num_primary_circles = 1      // XXS: 1 main circle
		if(256) num_primary_circles = 1      // XS: 1 main circle
		if(512) num_primary_circles = 2      // S: 2 overlapping
		if(768) num_primary_circles = 2      // M: 2 overlapping
		if(1024) num_primary_circles = 3     // L: 3 overlapping
		else num_primary_circles = 1

	var/list/all_circles = list()
	var/main_radius = round(size * 0.35)

	// Generate primary circles
	for(var/i = 1; i <= num_primary_circles; i++)
		var/cx, cy

		if(i == 1)
			// First circle centered near middle
			cx = round(size * 0.45)
			cy = round(size * 0.50)
		else
			// Additional circles offset from center
			var/angle = (i * 2 * PI) / num_primary_circles
			var/displacement = round(size * 0.15)
			cx = round((size * 0.5) + cos(angle) * displacement)
			cy = round((size * 0.5) + sin(angle) * displacement)

		all_circles += list(list(
			"x" = cx,
			"y" = cy,
			"radius" = main_radius
		))

	// Recursively add smaller circles at perimeter points
	all_circles = RecurseFractalCircles(all_circles, size, recursion_depth = 2)

	world << "Total circles for island shape: [all_circles.len]"

	// Mark all circles onto the map
	for(var/list/circle in all_circles)
		MarkCircleOnMap(map, circle["x"], circle["y"], circle["radius"], size)

	return map

world/proc/RecurseFractalCircles(var/list/circles, var/size, var/recursion_depth)
	if(recursion_depth <= 0) return circles

	var/new_circles = list()
	var/smaller_factor = 0.5  // Each recursion level halves the radius

	for(var/list/parent_circle in circles)
		var/parent_radius = parent_circle["radius"]
		var/smaller_radius = round(parent_radius * smaller_factor)

		// Don't recurse if circle is already too small
		if(smaller_radius < 5) continue

		// Number of child circles based on parent size
		var/num_children = rand(3, 5)

		for(var/j = 1; j <= num_children; j++)
			var/angle = rand(0, 2 * PI)
			// Place children near parent's edge
			var/distance_from_center = parent_radius - smaller_radius

			var/child_x = parent_circle["x"] + cos(angle) * distance_from_center
			var/child_y = parent_circle["y"] + sin(angle) * distance_from_center

			// Clamp to safe area
			child_x = cclamp(child_x, smaller_radius + 5, size - smaller_radius - 5)
			child_y = cclamp(child_y, smaller_radius + 5, size - smaller_radius - 5)

			new_circles += list(list(
				"x" = child_x,
				"y" = child_y,
				"radius" = smaller_radius
			))

	// Merge and recurse
	circles = circles + new_circles
	return RecurseFractalCircles(circles, size, recursion_depth - 1)

world/proc/InitializeEmptyMap(var/xmax, var/ymax)
	var/list/map = list()
	for(var/x = 1; x <= xmax; x++)
		for(var/y = 1; y <= ymax; y++)
			map["[x],[y]"] = TILE_OCEAN
	return map

world/proc/MarkCircleOnMap(var/list/map, var/cx, var/cy, var/radius, var/size)
	var/min_x = max(1, cx - radius)
	var/max_x = min(size, cx + radius)
	var/min_y = max(1, cy - radius)
	var/max_y = min(size, cy + radius)

	for(var/x = min_x; x <= max_x; x++)
		for(var/y = min_y; y <= max_y; y++)
			var/dist = DistanceFromCenter(x, y, cx, cy)
			if(dist < radius)
				map["[x],[y]"] = TILE_LAND

world/proc/DistanceFromCenter(var/x, var/y, var/cx, var/cy)
	return sqrt(pow(x - cx, 2) + pow(y - cy, 2))

// ============================================
// BIOME GRID SYSTEM
// ============================================

world/proc/ApplyBiomeGrid(var/list/map, var/size)
	var/grid_width = ceil(size / BIOME_GRID_SIZE)
	var/grid_height = ceil(size / BIOME_GRID_SIZE)

	// Generate biome centers (2-4 biomes per map)
	var/list/biome_centers = GenerateBiomeCenters(size)

	// Process each grid cell
	for(var/gx = 0; gx < grid_width; gx++)
		for(var/gy = 0; gy < grid_height; gy++)
			var/cell_x = gx * BIOME_GRID_SIZE + 1
			var/cell_y = gy * BIOME_GRID_SIZE + 1

			// Only process land cells
			if(map["[cell_x],[cell_y]"] == TILE_OCEAN) continue

			var/dominant_biome = GetDominantBiome(cell_x, cell_y, biome_centers)

			// Fill the entire cell with this biome
			for(var/x = cell_x; x < cell_x + BIOME_GRID_SIZE && x <= size; x++)
				for(var/y = cell_y; y < cell_y + BIOME_GRID_SIZE && y <= size; y++)
					if(map["[x],[y]"] == TILE_LAND)
						map["[x],[y]"] = "[dominant_biome]"  // Store biome name string

	return map

world/proc/GenerateBiomeCenters(var/size)
	var/list/centers = list()
	var/num_biomes = rand(2, 4)

	for(var/i = 1; i <= num_biomes; i++)
		var/biome_type
		switch(i)
			if(1) biome_type = "ice"
			if(2) biome_type = "desert"
			if(3) biome_type = "forest_dark"
			if(4) biome_type = "forest_light"

		var/cx = rand(BIOME_GRID_SIZE * 2, size - BIOME_GRID_SIZE * 2)
		var/cy = rand(BIOME_GRID_SIZE * 2, size - BIOME_GRID_SIZE * 2)

		centers += list(list(
			"type" = biome_type,
			"x" = cx,
			"y" = cy,
			"radius" = round(size * 0.30)
		))

	return centers

world/proc/GetDominantBiome(var/x, var/y, var/list/biome_centers)
	var/dominant_biome = "forest_light"  // Default
	var/max_influence = 0

	for(var/list/biome in biome_centers)
		var/dist = DistanceFromCenter(x, y, biome["x"], biome["y"])
		var/influence = (biome["radius"] - dist) / biome["radius"]

		if(influence > max_influence)
			max_influence = influence
			dominant_biome = biome["type"]

	return dominant_biome

// ============================================
// CLIFF BORDER GENERATION
// ============================================

world/proc/AddCliffBorders(var/list/map, var/size)
	// Scan all tiles and check for biome transitions
	for(var/x = 1; x <= size; x++)
		for(var/y = 1; y <= size; y++)
			var/key = "[x],[y]"
			if(map[key] == TILE_OCEAN || IsLandTile(map[key])) continue

			var/current_biome = map[key]

			// Check if adjacent to different biome
			if(HasAdjacentDifferentBiome(map, x, y, current_biome, size))
				// Random cliff width 2-6 tiles
				var/cliff_chance = round(clamp((CLIFF_WIDTH_MAX - CLIFF_WIDTH_MIN + 1), 0, 1))
				if(rand(1, 100) <= 50)
					map[key] = TILE_CLIFF

	return map

world/proc/IsLandTile(var/tile_value)
	return (tile_value == TILE_LAND || tile_value == TILE_CLIFF)

world/proc/HasAdjacentDifferentBiome(var/list/map, var/x, var/y, var/current_biome, var/size)
	for(var/offset in list(list(-1,0),list(1,0),list(0,-1),list(0,1)))
		var/nx = x + offset[1]
		var/ny = y + offset[2]

		if(nx < 1 || nx > size || ny < 1 || ny > size) continue

		var/nkey = "[nx],[ny]"
		if(!IsLandTile(map[nkey])) continue

		var/neighbor_biome = map[nkey]

		// If neighbor is a different biome string, this is a border
		if(neighbor_biome != current_biome)
			return TRUE

	return FALSE

// ============================================
// VOLCANO PLACEMENT
// ============================================

world/proc/PlaceVolcanoes(var/size)
	if(len(VolcanoBiomes) == 0)
		world << "No volcano biomes configured"
		return

	var/chosen_biome = VolcanoBiomes[rand(1, len(VolcanoBiomes))]
	world << "Placing volcano in [chosen_biome] biome"

	// Find the center of the chosen biome type
	// For now, scan all tiles and find cluster centers
	var/found_biome = FindBiomeCenter(chosen_biome, size)

	if(found_biome)
		var/volcano_loc = locate(found_biome["x"], found_biome["y"], 1)
		// Spawn volcano turf (implement after you add the turf type)
		world << "Volcano placed at [found_biome["x"]],[found_biome["y"]]"

world/proc/FindBiomeCenter(var/biome_type, var/size)
	var/list/positions = list()

	// Collect all tiles of this biome
	for(var/x = 1; x <= size; x++)
		for(var/y = 1; y <= size; y++)
			if(map["[x],[y]"] == biome_type)
				positions += list(list("x" = x, "y" = y))

	if(positions.len == 0) return null

	// Calculate average position
	var/total_x = 0, var/total_y = 0
	for(var/list/pos in positions)
		total_x += pos["x"]
		total_y += pos["y"]

	return list(
		"x" = round(total_x / positions.len),
		"y" = round(total_y / positions.len)
	)

// ============================================
// MAP COMMIT
// ============================================

world/proc/CommitMapToTurfs(var/list/map, var/size)
	var/start_tick = world.time

	for(var/x = 1; x <= size; x++)
		for(var/y = 1; y <= size; y++)
			var/key = "[x],[y]"
			var/turf_type = map[key]
			var/turf_loc = locate(x, y, 1)

			// Clear existing contents safely (without iteration)
			turf_loc.overlays = null
			turf_loc.underlays = null

			switch(turf_type)
				if(TILE_OCEAN)
					new/turf/Water(turf_loc)
				if(TILE_CLIFF)
					// Cliff tile - will use auto-connect later
					new/turf/Grass(turf_loc)  // Temp
					// Later: new/turf/Cliff(turf_loc)
				else
					// It's a biome string, look up the turf
					var/turf_path = BiomeToTurf[turf_type]
					if(turf_path)
						// Spawn appropriate turf based on biome
						new/turf/Grass(turf_loc)  // Placeholder for now
					else
						new/turf/Grass(turf_loc)

	world << "Map committed in [(world.time - start_tick)] ticks"

// ============================================
// HELPER FUNCTIONS
// ============================================

world/proc/cclamp(var/value, var/min, var/max)
	if(value < min) return min
	if(value > max) return max
	return value

proc/pow(var/base, var/exponent)
	return base ** exponent
proc/len(var/list/listvar)
	return listvar.len