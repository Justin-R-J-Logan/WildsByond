mob/Login()
	..()
	loc = locate(1,1,1)

world/New()
	..()

mob/verb/Gen()
	var/xmax = world.maxx
	var/ymax = world.maxy

	GenerateWorld()
	/*Generation
	Stuff
	Here*/
	//TODO: redo for loop later to include tiles that the genertator makes



mob/proc/MapKey(var/x, var/y)
	return "[x],[y]"

mob/proc/GenerateWorld()
	var/list/landmap = GenerateLandmass()
	//GenerateBiomes()
	//GenerateRivers()
	//GenerateFeatures()
	//GenerateTerrain()
	CommitMap(landmap)


mob/proc/GenerateLandmass()
	var/xmax = world.maxx
	var/ymax = world.maxy

	var/list/landmap = InitializeLandMap(xmax, ymax)

	var/list/seeds = GenerateLandSeeds(landmap)

	GrowLand(landmap, seeds)

	world << "Landmass complete"

	return landmap

mob/proc/InitializeLandMap(var/xmax, var/ymax)
	var/list/landmap = list()
	for(var/x = 1, x <= xmax, x++)
		for(var/y = 1, y <= ymax, y++)
			landmap["[x],[y]"] = TILE_OCEAN
	return landmap

mob/proc/GenerateLandSeeds(var/list/landmap)
	var/list/seeds = list()

	var/xmax = world.maxx
	var/ymax = world.maxy

	var/seed_count = 3
	var/target_size = 1000

	for(var/i = 1, i <= seed_count, i++)
		var/x = rand(2, xmax - 1)
		var/y = rand(2, ymax - 1)
		var/key = "[x],[y]"

		while(seeds[key])
			x = rand(2, xmax - 1)
			y = rand(2, ymax - 1)
			key = "[x],[y]"

		seeds[key] = list(
			"x" = x,
			"y" = y,
			"target_size" = target_size
		)

		landmap[key] = TILE_LAND

	return seeds

mob/proc/GrowLand(var/list/landmap, var/list/seeds)
	var/list/frontier = list()

	var/xmax = world.maxx
	var/ymax = world.maxy

	var/target_land = round((xmax * ymax) * 0.45)
	var/land_count = seeds.len

	// Add the neighbors of each seed to the frontier.
	for(var/key in seeds)
		var/list/seed = seeds[key]

		var/x = seed["x"]
		var/y = seed["y"]

		var/list/neighbors = list(
			list(x + 1, y),
			list(x - 1, y),
			list(x, y + 1),
			list(x, y - 1)
		)

		for(var/list/neighbor in neighbors)
			var/nx = neighbor[1]
			var/ny = neighbor[2]

			if(nx < 1 || nx > xmax || ny < 1 || ny > ymax)
				continue

			var/nkey = "[nx],[ny]"

			if(landmap[nkey] == TILE_OCEAN)
				frontier += list(list(
					"x" = nx,
					"y" = ny
				))

	// Grow outward from the frontier.
	while(frontier.len > 0 && land_count < target_land)
		var/index = rand(1, frontier.len)
		var/list/tile = frontier[index]

		frontier.Cut(index, index + 1)

		var/x = tile["x"]
		var/y = tile["y"]
		var/key = "[x],[y]"

		// This tile may have already been claimed.
		if(landmap[key] == TILE_LAND)
			continue

		// Claim the tile.
		landmap[key] = TILE_LAND
		land_count++

		// Add its neighbors to the frontier.
		var/list/neighbors = list(
			list(x + 1, y),
			list(x - 1, y),
			list(x, y + 1),
			list(x, y - 1)
		)

		for(var/list/neighbor in neighbors)
			var/nx = neighbor[1]
			var/ny = neighbor[2]

			if(nx < 1 || nx > xmax || ny < 1 || ny > ymax)
				continue

			var/nkey = "[nx],[ny]"

			if(landmap[nkey] == TILE_OCEAN)
				frontier += list(list(
					"x" = nx,
					"y" = ny
				))

/*mob/proc/GenerateLandmass()
	var/xmax = world.maxx
	var/ymax = world.maxy
	var/list/landmap = list()
	// Fill the map with ocean
	for(var/x = 1, x <= xmax, x++)
		for(var/y = 1, y <= ymax, y++)
			landmap["[x],[y]"] = TILE_OCEAN
	// Pick the center of the map as our initial land
	var/start_x = round(xmax / 2)
	var/start_y = round(ymax / 2)
	landmap["[start_x],[start_y]"] = TILE_LAND
	// Grow the island
	var/land_tiles = 1
	var/target_land = round((xmax * ymax) * 0.40)
	while(land_tiles < target_land)
		var/x = rand(2, xmax - 1)
		var/y = rand(2, ymax - 1)
		// Only grow from an existing land tile
		if(landmap["[x],[y]"] != TILE_LAND)
			continue
		var/direction = rand(1,4)
		var/new_x = x
		var/new_y = y
		switch(direction)
			if(1) new_x++
			if(2) new_x--
			if(3) new_y++
			if(4) new_y--
		// Don't grow into the map border
		if(new_x <= 1 || new_x >= xmax || new_y <= 1 || new_y >= ymax)
			continue
		if(landmap["[new_x],[new_y]"] == TILE_OCEAN)
			landmap["[new_x],[new_y]"] = TILE_LAND
			land_tiles++
	world << "Landmass complete: [land_tiles] land tiles"
	return landmap*/

/*mob/proc/GenerateLandmass()
	var/xmax = world.maxx
	var/ymax = world.maxy
	var/list/landmap = list()
	for(var/x = 1, x <= xmax, x++)
		for(var/y = 1, y <= ymax, y++)
			landmap[MapKey(x,y)] = TILE_OCEAN
	world << "Gen Complete"
	return landmap*/




mob/proc/CommitMap(var/list/landmap)
	var/xmax = world.maxx
	var/ymax = world.maxy
	for(var/x=1, x<=xmax, x++)
		for(var/y=1, y<=ymax, y++)
			if(landmap[MapKey(x,y)]==TILE_OCEAN) new/turf/Water/(locate(x,y,1))
			if(landmap[MapKey(x,y)]==TILE_LAND) new/turf/Grass/(locate(x,y,1))

	world << "placement complete"