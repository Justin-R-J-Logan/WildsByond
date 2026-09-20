#define TILE_OCEAN 0
#define TILE_LAND 1
#define TILE_COASTLINE 2  // New: temporary marker for shoreline processing

#define MAP_XS 256
#define MAP_S 512
#define MAP_M 768
#define MAP_L 1024

#define PI 3.14159265

mob/verb/Gen2()
	world.Generate()

// ============================================
// ISLAND SHAPE GENERATION
// ============================================

world/proc/Generate()
    /*
        Master entry point for world generation.
        Generates island shape first, then commits to turf.
    */
    var/world_size = GetNextMapSize() // XS, S, M, L

    // Initialize coordinate system
    world.maxx = world_size
    world.maxy = world_size
    world.maxz = 1

    // Generate raw land/water mask
    var/list/map_data = GenerateIslandShape(world_size)

    // Apply coastline fractalization
    map_data = ApplyCoastlineNoise(map_data, world_size)

    // Commit to actual turfs
    CommitMapToTurfs(map_data, world_size)

    world << "Island generation complete ([world_size]x[world_size])"

// ============================================
// CORE GENERATION FUNCTIONS
// ============================================

world/proc/GenerateIslandShape(var/size)
    /*
        Creates an island mask using overlapping circles.
        Returns associative list: "[x],[y]" -> TILE_LAND/TILE_OCEAN
    */
    var/list/map = InitializeEmptyMap(size, size)

    // Primary island center (offset from absolute center for asymmetry)
    var/primary_center_x = round(size * 0.45)
    var/primary_center_y = round(size * 0.50)
    var/primary_radius = round(size * 0.40)

    // Secondary islands (optional overlaps for archipelago feel)
    var/list/secondary_centers = GenerateSecondaryCenters(size, primary_center_x, primary_center_y)

    // Mark primary island
    for(var/x = 1, x <= size, x++)
        for(var/y = 1, y <= size, y++)
            var/dist = DistanceFromCenter(x, y, primary_center_x, primary_center_y)

            if(dist < primary_radius)
                map["[x],[y]"] = TILE_LAND
            else if(dist < primary_radius + 8)
                // Edge band - will be processed by coastline
                map["[x],[y]"] = TILE_COASTLINE // Temporary marker

    // Merge secondary islands
    for(var/list/center in secondary_centers)
        MarkCircleOnMap(map, center["x"], center["y"], center["radius"], size)

    return map

world/proc/InitializeEmptyMap(var/xmax, var/ymax)
    var/list/map = list()
    for(var/x = 1, x <= xmax, x++)
        for(var/y = 1, y <= ymax, y++)
            map["[x],[y]"] = TILE_OCEAN
    return map

world/proc/DistanceFromCenter(var/x, var/y, var/cx, var/cy)
    return sqrt(pow(x - cx, 2) + pow(y - cy, 2))

world/proc/MarkCircleOnMap(var/list/map, var/cx, var/cy, var/radius, var/size)
    var/min_x = max(1, cx - radius)
    var/max_x = min(size, cx + radius)
    var/min_y = max(1, cy - radius)
    var/max_y = min(size, cy + radius)

    for(var/x = min_x, x <= max_x, x++)
        for(var/y = min_y, y <= max_y, y++)
            var/dist = DistanceFromCenter(x, y, cx, cy)
            if(dist < radius)
                // Preserve existing landmass if already marked
                if(map["[x],[y]"] != TILE_LAND && map["[x],[y]"] != TILE_COASTLINE)
                    map["[x],[y]"] = TILE_LAND

world/proc/GenerateSecondaryCenters(var/size, var/primary_x, var/primary_y)
    /*
        Generate 1-3 secondary island clusters near primary.
        Adjust for desired archipelago density.
    */
    var/list/centers = list()
    var/num_secondary = rand(1, 3)
    var/spacing = round(size * 0.30)
    var/small_radius = round(size * 0.15)

    for(var/i = 1, i <= num_secondary, i++)
        var/angle = rand(0, 2 * PI)
        var/distance = rand(spacing * 0.5, spacing * 1.5)

        var/ex = primary_x + cos(angle) * distance
        var/ey = primary_y + sin(angle) * distance

        // Clamp to safe area (away from edges)
        ex = cclamp(round(ex), 10, size - 10)
        ey = cclamp(round(ey), 10, size - 10)

        centers += list(list(
            "x" = ex,
            "y" = ey,
            "radius" = rand(round(small_radius * 0.5), small_radius)
        ))

    return centers

// ============================================
// COASTLINE FRACTALIZATION
// ============================================

world/proc/ApplyCoastlineNoise(var/list/map, var/size)
    /*
        Modifies coastal tiles to create jagged, natural shorelines.
        Uses simple random walk algorithm for each coastal segment.
    */
    var/list/coast_tiles = FindCoastlineTiles(map, size)
    var/noise_amount = rand(3, 8) // Tiles of distortion

    for(var/key in coast_tiles)
        var/list/coast = ParseKey(key)
        var/x = coast["x"]
        var/y = coast["y"]

        // Randomly push or pull land
        if(rand(1, 100) <= 50)
            // Erode: turn land tile into water
            map[key] = TILE_OCEAN
        else
            // Accrete: extend land into ocean
            var/extend_x = x + rand(-1, 1)
            var/extend_y = y + rand(-1, 1)
            var/new_key = "[extend_x],[extend_y]"

            if(map[new_key] == TILE_OCEAN)
                map[new_key] = TILE_LAND

    return map

world/proc/FindCoastlineTiles(var/list/map, var/size)
    var/list/coast = list()

    for(var/x = 1, x <= size, x++)
        for(var/y = 1, y <= size, y++)
            var/key = "[x],[y]"
            if(map[key] == TILE_COASTLINE || IsEdgeOfLand(map, x, y, size))
                coast[key] = 1

    return coast

world/proc/IsEdgeOfLand(var/list/map, var/x, var/y, var/size)
    var/is_land = map["[x],[y]"] == TILE_LAND || map["[x],[y]"] == TILE_COASTLINE

    for(var/offset in list(list(-1,0),list(1,0),list(0,-1),list(0,1)))
        var/nx = x + offset[1]
        var/ny = y + offset[2]

        if(nx < 1 || nx > size || ny < 1 || ny > size)
            continue

        var/neighbour_type = map["[nx],[ny]"]

        if(is_land && neighbour_type == TILE_OCEAN)
            return TRUE
        if(!is_land && neighbour_type == TILE_LAND)
            return TRUE

    return FALSE

// ============================================
// MAP COMMIT
// ============================================

world/proc/CommitMapToTurfs(var/list/map, var/size)
    var/start_tick = world.time

    for(var/x = 1, x <= size, x++)
        for(var/y = 1, y <= size, y++)
            var/key = "[x],[y]"
            var/turf_type = map[key]
            var/turf_loc = locate(x, y, 1)

            switch(turf_type)
                if(TILE_LAND)
                    new/turf/Grass(turf_loc)
                else
                    new/turf/Water(turf_loc)

    world << "Map committed in [(world.time - start_tick)] ticks"


world/proc/GetNextMapSize()
    // Returns preset based on config or random
    // Could read from config file:
    // var/config_size = config.MapSize("M")
    // return parse_size(config_size)

    var/list/preset_list = list(MAP_XS, MAP_S, MAP_M, MAP_L)
    return preset_list[1]

world/proc/ParseKey(var/key)
    var/list/result = list()
    var/parts = splittext(key, ",")
    result["x"] = text2num(parts[1])
    result["y"] = text2num(parts[2])
    return result

// Built-in clamp if not available in your DM version
world/proc/cclamp(var/value, var/min, var/max)
    if(value < min) return min
    if(value > max) return max
    return value

proc/pow(var/base, var/exponent)
	return base ** exponent