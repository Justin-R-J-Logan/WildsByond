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

// ============================================================
// DRAWING FUNCTION TEST
// ============================================================
//
// Generates a 256x256 map containing a grid of every drawing
// function created so far.
//
// Each shape has its own cell so that the results can be
// inspected individually.
//
// Grid:
//
//     +---------+---------+---------+---------+
//     | Circle  | Filled  | Thick   | Thick   | Thick   |
//     |         | Circle  | Circle  | Inner   | Outer   |
//     +---------+---------+---------+---------+---------+
//     | Square  | Filled  | Thick   | Rounded | Filled  |
//     |         | Square  | Square  | Square  | Rnd Sq  |
//     +---------+---------+---------+---------+---------+
//     | Rect    | Filled  | Thick   | Rounded | Filled  |
//     |         | Rect    | Rect    | Rect    | Rnd Rect|
//     +---------+---------+---------+---------+---------+
//     | Triangle| Filled  | Rounded | Filled  | Hexagon |
//     |         | Triangle| Triangle| Rnd Tri |         |
//     +---------+---------+---------+---------+---------+
//     | Filled  | Rounded | Filled  | Rounded | Filled  |
//     | Hexagon | Hexagon | Rnd Hex | ...     | ...     |
//     +---------+---------+---------+---------+---------+
//
// ============================================================


// ============================================================
// DRAWING TEST MAP
// ============================================================

world/proc/TestDrawingMap()
	var/list/map = list()

	var/map_width = 256
	var/map_height = 256

	// --------------------------------------------------------
	// Fill the entire map with ocean.
	// --------------------------------------------------------

	for(var/x = 1, x <= map_width, x++)
		for(var/y = 1, y <= map_height, y++)
			MapSet(map, x, y, TILE_OCEAN)


	// ========================================================
	// CELL SIZE
	// ========================================================

	var/cell_width = 51
	var/cell_height = 51


	// ========================================================
	// ROW 1 - CIRCLES
	// ========================================================

	// Cell 1: DrawCircle
	DrawCircle(
		map,
		26, 230,
		15,
		TILE_ROCKY
	)

	// Cell 2: DrawFilledCircle
	DrawFilledCircle(
		map,
		77, 230,
		15,
		TILE_GRASS
	)

	// Cell 3: DrawThickCircle
	DrawThickCircle(
		map,
		128, 230,
		13,
		5,
		TILE_ROCKY
	)

	// Cell 4: DrawThickCircleInner
	DrawThickCircleInner(
		map,
		179, 230,
		16,
		5,
		TILE_ROCKY
	)

	// Cell 5: DrawThickCircleOuter
	DrawThickCircleOuter(
		map,
		230, 230,
		11,
		5,
		TILE_ROCKY
	)


	// ========================================================
	// ROW 2 - SQUARES
	// ========================================================

	// Cell 1: DrawSquare
	DrawSquare(
		map,
		12, 180,
		28,
		TILE_ROCKY
	)

	// Cell 2: DrawFilledSquare
	DrawFilledSquare(
		map,
		63, 180,
		28,
		TILE_GRASS
	)

	// Cell 3: DrawThickSquare
	DrawThickSquare(
		map,
		114, 180,
		28,
		5,
		TILE_ROCKY
	)

	// Cell 4: DrawRoundedSquare
	DrawRoundedSquare(
		map,
		165, 180,
		28,
		6,
		TILE_ROCKY
	)

	// Cell 5: DrawFilledRoundedSquare
	DrawFilledRoundedSquare(
		map,
		216, 180,
		28,
		6,
		TILE_GRASS
	)


	// ========================================================
	// ROW 3 - RECTANGLES
	// ========================================================

	// Cell 1: DrawRectangle
	DrawRectangle(
		map,
		5, 135,
		42, 28,
		TILE_ROCKY
	)

	// Cell 2: DrawFilledRectangle
	DrawFilledRectangle(
		map,
		56, 135,
		42, 28,
		TILE_GRASS
	)

	// Cell 3: DrawThickRectangle
	DrawThickRectangle(
		map,
		107, 135,
		42, 28,
		5,
		TILE_ROCKY
	)

	// Cell 4: DrawRoundedRectangle
	DrawRoundedRectangle(
		map,
		158, 135,
		42, 28,
		6,
		TILE_ROCKY
	)

	// Cell 5: DrawFilledRoundedRectangle
	DrawFilledRoundedRectangle(
		map,
		209, 135,
		42, 28,
		6,
		TILE_GRASS
	)


	// ========================================================
	// ROW 4 - TRIANGLES
	// ========================================================

	// Cell 1: DrawTriangle
	DrawTriangle(
		map,
		26, 85,
		30, 30,
		TILE_ROCKY
	)

	// Cell 2: DrawFilledTriangle
	DrawFilledTriangle(
		map,
		77, 85,
		30, 30,
		TILE_GRASS
	)

	// Cell 3: DrawRoundedTriangle
	DrawRoundedTriangle(
		map,
		128, 85,
		32, 30,
		5,
		TILE_ROCKY
	)

	// Cell 4: DrawFilledRoundedTriangle
	//DrawFilledRoundedTriangle(
	//	map,
	//	179, 85,
	//	32, 30,
	//	5,
	//	TILE_GRASS
	//)

	// Cell 5: Extra triangle test
	//
	// This deliberately combines an outline and fill so we
	// can verify that shapes layer correctly.

	DrawRoundedTriangle(
		map,
		230, 85,
		32, 30,
		5,
		TILE_ROCKY
	)

	DrawFilledTriangle(
		map,
		230, 85,
		22, 20,
		TILE_GRASS
	)


	// ========================================================
	// ROW 5 - HEXAGONS
	// ========================================================

	// Cell 1: DrawHexagon
	DrawHexagon(
		map,
		26, 32,
		17,
		TILE_ROCKY
	)

	// Cell 2: DrawFilledHexagon
	DrawFilledHexagon(
		map,
		77, 32,
		17,
		TILE_GRASS
	)

	// Cell 3: DrawRoundedHexagon
	/*DrawRoundedHexagon(
		map,
		128, 32,
		18,
		5,
		TILE_ROCKY
	)

	// Cell 4: DrawFilledRoundedHexagon
	DrawFilledRoundedHexagon(
		map,
		179, 32,
		18,
		5,
		TILE_GRASS
	)

	// Cell 5: Combined rounded hexagon test
	DrawRoundedHexagon(
		map,
		230, 32,
		19,
		5,
		TILE_ROCKY
	)*/

	DrawFilledHexagon(
		map,
		230, 32,
		14,
		TILE_GRASS
	)


	return map


// ============================================================
// TEST VERB
// ============================================================

mob/verb/TestDrawing()
	set name = "Test Drawing"
	set category = "Testing"

	world << "Generating 256x256 drawing test..."

	var/list/map = world.TestDrawingMap()

	world.CommitTestMap(map)

	world << "Drawing test complete."

// ============================================================
// TEST MAP COMMIT
// ============================================================

world/proc/CommitTestMap(var/list/map)
	var/xmax = 256
	var/ymax = 256

	for(var/x = 1, x <= xmax, x++)
		for(var/y = 1, y <= ymax, y++)
			var/tile = MapGet(map, x, y)

			if(tile == TILE_OCEAN)
				new /turf/Water(locate(x, y, 1))

			else if(tile == TILE_GRASS)
				new /turf/Grass(locate(x, y, 1))

			else if(tile == TILE_ROCKY)
				new /turf/Rocky(locate(x, y, 1))


// ============================================================
// ARC ANGLE TEST
// ============================================================
//
// Returns TRUE if angle lies between start_angle and
// end_angle, travelling counter-clockwise.
//
// This handles arcs that cross 0 degrees.
//
// ============================================================

world/proc/ArcContainsAngle(
	var/start_angle,
	var/end_angle,
	var/angle
)
	while(angle < 0)
		angle += 360

	while(angle >= 360)
		angle -= 360

	if(start_angle <= end_angle)
		return angle >= start_angle && angle <= end_angle

	// Arc crosses 360 degrees.
	return angle >= start_angle || angle <= end_angle

world/proc/TestArcs()
	set name = "Test Arcs"
	set category = "Debug"

	var/list/map = list()

	// Clear a reasonably sized test area.
	for(var/x = 1, x <= world.maxx, x++)
		for(var/y = 1, y <= world.maxy, y++)
			MapSet(map, x, y, TILE_OCEAN)

	// Quarter circles.
	DrawArc(map, 25, 25, 10, 0, 90, TILE_GRASS)
	DrawArc(map, 50, 25, 10, 90, 180, TILE_GRASS)
	DrawArc(map, 75, 25, 10, 180, 270, TILE_GRASS)
	DrawArc(map, 100, 25, 10, 270, 360, TILE_GRASS)

	// Half circles.
	DrawArc(map, 30, 55, 15, 0, 180, TILE_GRASS)
	DrawArc(map, 70, 55, 15, 180, 360, TILE_GRASS)

	// Three-quarter circle.
	DrawArc(map, 110, 55, 15, 0, 270, TILE_GRASS)

	// Arc crossing the 0-degree boundary.
	DrawArc(map, 30, 85, 15, 315, 45, TILE_GRASS)

	// Full circle.
	DrawArc(map, 70, 85, 15, 0, 0, TILE_GRASS)

	// Commit the test map to the actual world.
	CommitTestMap(map)

mob/verb/ArcTests()
	world.TestArcs()

world/proc/TestPaintFillGen()
	var/list/map = list()

	// Fill the entire temporary map with ocean.
	for(var/x = 1, x <= world.maxx, x++)
		for(var/y = 1, y <= world.maxy, y++)
			MapSet(map, x, y, TILE_OCEAN)

	// Draw a large circle in the center.
	var/cx = round(world.maxx / 2)
	var/cy = round(world.maxy / 2)
	var/radius = round(min(world.maxx, world.maxy) / 3)

	DrawCircle(map, cx, cy, radius, TILE_CLIFF)

	// Fill the interior of the circle.
	PaintFill(map, cx, cy, TILE_GRASS)

	CommitTestMap(map)

mob/verb/TestPaintFill()
	set name = "Test Paint Fill"
	set category = "Debug"

	world.TestPaintFillGen()