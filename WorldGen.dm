// ============================================================
// BASIC TERRAIN TILES
// ============================================================

// Water
#define TILE_OCEAN             1   // Open ocean
#define TILE_RIVER             2   // Moving/shallow river water
#define TILE_STILLWATER        3   // Lakes, ponds, etc.

// Coastal
#define TILE_BEACH             10  // Sandy beach / shoreline

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

world/proc/Generator()

	// ========================================================
	// GENERATION STAGES
	// ========================================================

	var/list/landmap = GenerateLandmass()

	var/list/biomemap = GenerateBiomes(landmap)

	var/list/rivermap = GenerateRivers(landmap, biomemap)

	var/list/featuremap = GenerateFeatures(landmap, biomemap, rivermap)

	var/list/terrainmap = GenerateTerrain(
		landmap,
		biomemap,
		rivermap,
		featuremap
	)

	// ========================================================
	// FINAL MAP CREATION
	// ========================================================

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