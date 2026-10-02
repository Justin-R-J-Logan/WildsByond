
// ============================================================
// LANDMASS GENERATION
// ============================================================

world/proc/GenerateLandmass()

	var/list/landmap = list()

	// Generate land seeds
	var/list/seeds = GenerateLandSeeds(landmap)

	// Grow land outward from seeds
	GrowLand(landmap, seeds)

	return landmap

world/proc/GenerateLandSeeds(var/list/landmap)

	var/list/seeds = list()

	// Generation code will go here.

	return seeds


world/proc/GrowLand(var/list/landmap, var/list/seeds)

	// Generation code will go here.

// ============================================================
// BIOME GENERATION
// ============================================================

world/proc/GenerateBiomes(var/list/landmap)

	var/list/biomemap = list()

	// Generation code will go here.

	return biomemap

// ============================================================
// RIVER GENERATION
// ============================================================

world/proc/GenerateRivers(var/list/landmap, var/list/biomemap)

	var/list/rivermap = list()

	// Generation code will go here.

	return rivermap

// ============================================================
// FEATURE GENERATION
// ============================================================

world/proc/GenerateFeatures(
	var/list/landmap,
	var/list/biomemap,
	var/list/rivermap
)

	var/list/featuremap = list()

	// Generation code will go here.

	return featuremap

// ============================================================
// TERRAIN GENERATION
// ============================================================

world/proc/GenerateTerrain(
	var/list/landmap,
	var/list/biomemap,
	var/list/rivermap,
	var/list/featuremap
)

	var/list/terrainmap = list()

	// Generation code will go here.

	return terrainmap

// ============================================================
// MAP COMMIT
// ============================================================

world/proc/CommitMap(
	var/list/landmap,
	var/list/biomemap,
	var/list/rivermap,
	var/list/featuremap,
	var/list/terrainmap
)

	// Actual turf creation will go here.