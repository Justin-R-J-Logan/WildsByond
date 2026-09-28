// ============================================================
// BASIC TERRAIN TILES
// ============================================================

// Water
#define TILE_EMPTY             0   // Empty tile - for copying maps onto maps
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
#define TILE_TALLGRASS         50
#define TILE_TALLGRASS_SAVANNAH 51
#define TILE_TALLGRASS_SNOWY   52
#define TILE_TALLGRASS_VOLCANO 53
#define TILE_TALLGRASS_GRAVEYARD 54

// Arid
#define TILE_DESERT            60

// ============================================================
// MAJOR SURFACE BIOMES
// ============================================================

#define BIOME_PRAIRIE          1
#define BIOME_FOREST           2
#define BIOME_DARK_FOREST      3
#define BIOME_ANCIENT_FOREST   4
#define BIOME_TROPICAL_JUNGLE  5
#define BIOME_SAVANNA          6
#define BIOME_DESERT           7
#define BIOME_BADLANDS         8
#define BIOME_TUNDRA           9
#define BIOME_MOUNTAIN         10
#define BIOME_VOLCANO          11
#define BIOME_ASHLANDS         12
#define BIOME_WETLANDS         13
#define BIOME_BEACH            14
#define BIOME_OCEAN            15

// ============================================================
// SPECIAL / LOCALIZED BIOMES
// ============================================================

#define BIOME_GRAVEYARD        20
#define BIOME_RUINS            21
#define BIOME_RIVER            22
#define BIOME_LAKE             23
#define BIOME_FROZEN_LAKE      24

// ============================================================
// UNDERGROUND / ALTERNATE BIOMES
// ============================================================

#define BIOME_CAVE             30
#define BIOME_MINE             31
#define BIOME_ICE_CAVE         32
#define BIOME_DRAGON_CAVE      33
#define BIOME_LAVA_CAVE        34
#define BIOME_WATER_CAVE       35


// ============================================================
// DRAWING FUNCTION TEST HARNESS
// ============================================================
//
// Generates a 256x256 testing map divided into 16x16 cells.
//
// The grid begins at the top-left corner of the map:
//     (1, 256, 1)
//
// Because 256 / 16 = 16, there are 16 columns and 16 rows,
// giving us room for 256 individual drawing tests.
//
// Each drawing proc gets one cell. A clickable marker is placed
// in the top-left tile of each used cell. Clicking the marker
// prints the name of the proc being tested.
//
// ============================================================

#define TEST_MAP_SIZE       256
#define TEST_CELL_SIZE      16
#define TEST_GRID_COLUMNS   16


// ============================================================
// TEST SHAPE LABEL
// ============================================================

obj/TestingShapeLabel
	icon = 'Tiles.dmi'
	icon_state = "ground_rocky_02"

	var/test_name = "Unknown Test"

	New(var/location, var/label)
		..()

		if(label)
			test_name = label

		name = "Test: [test_name]"

	Click()
		world << "Shape test: [test_name]"


// ============================================================
// GET TEST CELL
// ============================================================
//
// Returned list:
//
//     [1] = left X
//     [2] = bottom Y
//     [3] = top Y
//     [4] = center X
//     [5] = center Y
//
// ============================================================

world/proc/GetTestingCell(var/index)
	if(index < 1 || index > 256)
		return null

	var/zero_index = index - 1
	var/column = zero_index % TEST_GRID_COLUMNS
	var/row = (zero_index - column) / TEST_GRID_COLUMNS

	var/left_x = 1 + (column * TEST_CELL_SIZE)
	var/top_y = TEST_MAP_SIZE - (row * TEST_CELL_SIZE)
	var/bottom_y = top_y - TEST_CELL_SIZE + 1

	var/center_x = left_x + 7
	var/center_y = bottom_y + 7

	return list(
		left_x,
		bottom_y,
		top_y,
		center_x,
		center_y
	)


// ============================================================
// ADD TEST LABEL
// ============================================================

world/proc/AddTestingLabel(var/index, var/test_name)
	var/list/cell = GetTestingCell(index)

	if(!cell)
		return

	var/left_x = cell[1]
	var/top_y = cell[3]

	var/turf/T = locate(left_x, top_y, 1)

	if(T)
		new /obj/TestingShapeLabel(T, test_name)


// ============================================================
// COMMIT TESTING MAP
// ============================================================

world/proc/CommitTestingMap(var/list/map)
	for(var/x = 1, x <= TEST_MAP_SIZE, x++)
		for(var/y = 1, y <= TEST_MAP_SIZE, y++)
			var/tile = MapGet(map, x, y)
			var/turf/T = locate(x, y, 1)

			if(!T)
				continue

			if(tile == TILE_OCEAN)
				new /turf/Water(T)

			else if(tile == TILE_GRASS)
				new /turf/Grass(T)

			else if(tile == TILE_ROCKY)
				new /turf/Rocky(T)

			else if(tile == TILE_DESERT)
				new /turf/Desert(T)


// ============================================================
// GENERATE TESTING MAP
// ============================================================

world/proc/GenerateTestingMap()
	world.maxx = TEST_MAP_SIZE
	world.maxy = TEST_MAP_SIZE

	// Remove labels left over from previous test generations.
	for(var/obj/TestingShapeLabel/L in world)
		del(L)

	var/list/map = list()

	// Fill the entire generated map with ocean.
	for(var/x = 1, x <= TEST_MAP_SIZE, x++)
		for(var/y = 1, y <= TEST_MAP_SIZE, y++)
			MapSet(map, x, y, TILE_OCEAN)


	// ========================================================
	// TEST 1 - DrawPixel
	// ========================================================

	var/list/cell = GetTestingCell(1)
	DrawPixel(map, cell[4], cell[5], TILE_ROCKY)


	// ========================================================
	// TEST 2 - DrawHorizontalLine
	// ========================================================

	cell = GetTestingCell(2)
	DrawHorizontalLine(map, cell[1] + 2, cell[5], 12, TILE_ROCKY)


	// ========================================================
	// TEST 3 - DrawVerticalLine
	// ========================================================

	cell = GetTestingCell(3)
	DrawVerticalLine(map, cell[4], cell[2] + 2, 12, TILE_ROCKY)


	// ========================================================
	// TEST 4 - DrawLine
	// ========================================================

	cell = GetTestingCell(4)
	DrawLine(
		map,
		cell[1] + 2,
		cell[2] + 2,
		cell[1] + 13,
		cell[3] - 2,
		TILE_ROCKY
	)


	// ========================================================
	// TEST 5 - DrawArc
	// ========================================================

	cell = GetTestingCell(5)
	DrawArc(map, cell[4], cell[5], 5, 20, 250, TILE_ROCKY)


	// ========================================================
	// TEST 6 - PaintFill
	// ========================================================

	cell = GetTestingCell(6)

	var/fill_left = cell[1] + 3
	var/fill_right = cell[1] + 12
	var/fill_bottom = cell[2] + 3
	var/fill_top = cell[3] - 3

	for(var/fill_x = fill_left, fill_x <= fill_right, fill_x++)
		MapSet(map, fill_x, fill_bottom, TILE_ROCKY)
		MapSet(map, fill_x, fill_top, TILE_ROCKY)

	for(var/fill_y = fill_bottom, fill_y <= fill_top, fill_y++)
		MapSet(map, fill_left, fill_y, TILE_ROCKY)
		MapSet(map, fill_right, fill_y, TILE_ROCKY)

	PaintFill(map, cell[4], cell[5], TILE_GRASS)


	// ========================================================
	// TEST 7 - DrawCircle
	// ========================================================

	cell = GetTestingCell(7)
	DrawCircle(map, cell[4], cell[5], 5, TILE_ROCKY)


	// ========================================================
	// TEST 8 - DrawFilledCircle
	// ========================================================

	cell = GetTestingCell(8)
	DrawFilledCircle(map, cell[4], cell[5], 5, TILE_GRASS)


	// ========================================================
	// TEST 9 - DrawRectangle
	// ========================================================

	cell = GetTestingCell(9)
	DrawRectangle(map, cell[1] + 2, cell[2] + 3, 12, 10, TILE_ROCKY)


	// ========================================================
	// TEST 10 - DrawFilledRectangle
	// ========================================================

	cell = GetTestingCell(10)
	DrawFilledRectangle(map, cell[1] + 2, cell[2] + 3, 12, 10, TILE_GRASS)


	// ========================================================
	// TEST 11 - DrawTriangle
	// ========================================================

	cell = GetTestingCell(11)
	DrawTriangle(map, cell[4], cell[2] + 2, 11, 11, TILE_ROCKY)


	// ========================================================
	// TEST 12 - DrawFilledTriangle
	// ========================================================

	cell = GetTestingCell(12)
	DrawFilledTriangle(map, cell[4], cell[2] + 2, 11, 11, TILE_GRASS)


	// ========================================================
	// TEST 13 - DrawHexagon
	// ========================================================

	cell = GetTestingCell(13)
	DrawHexagon(map, cell[4], cell[5], 5, TILE_ROCKY)


	// ========================================================
	// TEST 14 - DrawFilledHexagon
	// ========================================================

	cell = GetTestingCell(14)
	DrawFilledHexagon(map, cell[4], cell[5], 5, TILE_GRASS)


	// ========================================================
	// TEST 15 - DrawThickCircle
	// ========================================================

	cell = GetTestingCell(15)
	DrawThickCircle(map, cell[4], cell[5], 4, 3, TILE_ROCKY)


	// ========================================================
	// TEST 16 - DrawThickCircleInner
	// ========================================================

	cell = GetTestingCell(16)
	DrawThickCircleInner(map, cell[4], cell[5], 6, 3, TILE_ROCKY)


	// ========================================================
	// TEST 17 - DrawThickCircleOuter
	// ========================================================

	cell = GetTestingCell(17)
	DrawThickCircleOuter(map, cell[4], cell[5], 4, 2, TILE_ROCKY)


	// ========================================================
	// TEST 18 - DrawSquare
	// ========================================================

	cell = GetTestingCell(18)
	DrawSquare(map, cell[1] + 3, cell[2] + 3, 10, TILE_ROCKY)


	// ========================================================
	// TEST 19 - DrawFilledSquare
	// ========================================================

	cell = GetTestingCell(19)
	DrawFilledSquare(map, cell[1] + 3, cell[2] + 3, 10, TILE_GRASS)


	// ========================================================
	// TEST 20 - DrawThickSquare
	// ========================================================

	cell = GetTestingCell(20)
	DrawThickSquare(map, cell[1] + 2, cell[2] + 2, 11, 3, TILE_ROCKY)


	// ========================================================
	// TEST 21 - DrawThickRectangle
	// ========================================================

	cell = GetTestingCell(21)
	DrawThickRectangle(map, cell[1] + 2, cell[2] + 3, 12, 10, 3, TILE_ROCKY)


	// ========================================================
	// TEST 22 - DrawRoundedRectangle
	// ========================================================

	cell = GetTestingCell(22)
	DrawRoundedRectangle(map, cell[1] + 2, cell[2] + 3, 12, 10, 3, TILE_ROCKY)


	// ========================================================
	// TEST 23 - DrawFilledRoundedRectangle
	// ========================================================

	cell = GetTestingCell(23)
	DrawFilledRoundedRectangle(map, cell[1] + 2, cell[2] + 3, 12, 10, 3, TILE_GRASS)


	// ========================================================
	// TEST 24 - DrawRoundedSquare
	// ========================================================

	cell = GetTestingCell(24)
	DrawRoundedSquare(map, cell[1] + 2, cell[2] + 2, 11, 3, TILE_ROCKY)


	// ========================================================
	// TEST 25 - DrawFilledRoundedSquare
	// ========================================================

	cell = GetTestingCell(25)
	DrawFilledRoundedSquare(map, cell[1] + 2, cell[2] + 2, 11, 3, TILE_GRASS)


	// ========================================================
	// TEST 26 - DrawLobedTriangle
	// ========================================================

	cell = GetTestingCell(26)
	DrawLobedTriangle(map, cell[4], cell[2] + 2, 10, 10, 2, TILE_ROCKY)


	// ========================================================
	// TEST 27 - DrawFilledLobedTriangle
	// ========================================================

	cell = GetTestingCell(27)
	DrawFilledLobedTriangle(map, cell[4], cell[2] + 2, 10, 10, 2, TILE_GRASS)


	// ========================================================
	// TEST 28 - DrawLobedHexagon
	// ========================================================

	cell = GetTestingCell(28)
	DrawLobedHexagon(map, cell[4], cell[5], 5, 2, TILE_ROCKY)


	// ========================================================
	// TEST 29 - DrawFilledLobedHexagon
	// ========================================================

	cell = GetTestingCell(29)
	DrawFilledLobedHexagon(map, cell[4], cell[5], 5, 2, TILE_GRASS)


	// ========================================================
	// TEST 30 - DrawRoundedTriangle
	// ========================================================

	cell = GetTestingCell(30)
	DrawRoundedTriangle(map, cell[4], cell[2] + 2, 11, 11, 2, TILE_ROCKY)

	// ========================================================
	// TEST 31 - DrawThickLine thickness 1
	// ========================================================

	cell = GetTestingCell(31)
	DrawThickLine(
		map,
		cell[1] + 2,
		cell[2] + 2,
		cell[1] + 13,
		cell[3] - 2,
		1,
		TILE_ROCKY
	)


	// ========================================================
	// TEST 32 - DrawThickLine thickness 3
	// ========================================================

	cell = GetTestingCell(32)
	DrawThickLine(
		map,
		cell[1] + 2,
		cell[2] + 2,
		cell[1] + 13,
		cell[3] - 2,
		3,
		TILE_ROCKY
	)


	// ========================================================
	// TEST 33 - DrawThickLine thickness 5
	// ========================================================

	cell = GetTestingCell(33)
	DrawThickLine(
		map,
		cell[1] + 2,
		cell[2] + 2,
		cell[1] + 13,
		cell[3] - 2,
		5,
		TILE_ROCKY
	)


	// ========================================================
	// TEST 34 - DrawThickLine thickness 7
	// ========================================================

	cell = GetTestingCell(34)
	DrawThickLine(
		map,
		cell[1] + 2,
		cell[2] + 2,
		cell[1] + 13,
		cell[3] - 2,
		7,
		TILE_ROCKY
	)
	// ========================================================
	// TEST 35 - DrawPolyline
	// ========================================================

	cell = GetTestingCell(35)

	var/list/polyline_points = list(
		list(cell[1] + 2,  cell[2] + 3),
		list(cell[1] + 5,  cell[3] - 3),
		list(cell[1] + 8,  cell[2] + 5),
		list(cell[1] + 11, cell[3] - 4),
		list(cell[1] + 13, cell[2] + 7)
	)

	DrawPolyline(
		map,
		polyline_points,
		TILE_ROCKY
	)

	// ========================================================
	// TEST 36 - DrawThickPolyline
	// ========================================================

	cell = GetTestingCell(36)

	var/list/thick_polyline_points = list(
		list(cell[1] + 2,  cell[2] + 3),
		list(cell[1] + 5,  cell[3] - 3),
		list(cell[1] + 8,  cell[2] + 5),
		list(cell[1] + 11, cell[3] - 4),
		list(cell[1] + 13, cell[2] + 7)
	)

	DrawThickPolyline(
		map,
		thick_polyline_points,
		3,
		TILE_ROCKY
	)
	// ========================================================
	// TEST 37 - DrawPolygon
	// ========================================================

	cell = GetTestingCell(37)

	var/list/polygon_points = list(
		list(cell[1] + 3,  cell[2] + 3),
		list(cell[1] + 5,  cell[3] - 3),
		list(cell[1] + 10, cell[3] - 4),
		list(cell[1] + 13, cell[2] + 7),
		list(cell[1] + 9,  cell[2] + 2)
	)

	DrawPolygon(
		map,
		polygon_points,
		TILE_ROCKY
	)
	// ========================================================
	// TEST 38 - DrawFilledPolygon
	// ========================================================

	cell = GetTestingCell(38)

	var/list/filled_polygon_points = list(
		list(cell[1] + 3,  cell[2] + 3),
		list(cell[1] + 5,  cell[3] - 3),
		list(cell[1] + 10, cell[3] - 4),
		list(cell[1] + 13, cell[2] + 7),
		list(cell[1] + 9,  cell[2] + 2)
	)

	DrawFilledPolygon(
		map,
		filled_polygon_points,
		TILE_GRASS
	)
	// ========================================================
	// TEST 39 - DrawNgon Triangle
	// ========================================================

	cell = GetTestingCell(39)

	DrawNgon(
		map,
		cell[4],
		cell[5],
		5,
		3,
		90,
		TILE_ROCKY
	)


	// ========================================================
	// TEST 40 - DrawNgon Square
	// ========================================================

	cell = GetTestingCell(40)

	DrawNgon(
		map,
		cell[4],
		cell[5],
		5,
		4,
		45,
		TILE_ROCKY
	)


	// ========================================================
	// TEST 41 - DrawNgon Pentagon
	// ========================================================

	cell = GetTestingCell(41)

	DrawNgon(
		map,
		cell[4],
		cell[5],
		5,
		5,
		90,
		TILE_ROCKY
	)


	// ========================================================
	// TEST 42 - DrawNgon Hexagon
	// ========================================================

	cell = GetTestingCell(42)

	DrawNgon(
		map,
		cell[4],
		cell[5],
		5,
		6,
		30,
		TILE_ROCKY
	)


	// ========================================================
	// TEST 43 - DrawNgon Octagon
	// ========================================================

	cell = GetTestingCell(43)

	DrawNgon(
		map,
		cell[4],
		cell[5],
		5,
		8,
		22.5,
		TILE_ROCKY
	)
	// ========================================================
	// TEST 44 - DrawFilledNgon Triangle
	// ========================================================

	cell = GetTestingCell(44)

	DrawFilledNgon(
		map,
		cell[4],
		cell[5],
		5,
		3,
		90,
		TILE_GRASS
	)


	// ========================================================
	// TEST 45 - DrawFilledNgon Square
	// ========================================================

	cell = GetTestingCell(45)

	DrawFilledNgon(
		map,
		cell[4],
		cell[5],
		5,
		4,
		45,
		TILE_GRASS
	)


	// ========================================================
	// TEST 46 - DrawFilledNgon Pentagon
	// ========================================================

	cell = GetTestingCell(46)

	DrawFilledNgon(
		map,
		cell[4],
		cell[5],
		5,
		5,
		90,
		TILE_GRASS
	)


	// ========================================================
	// TEST 47 - DrawFilledNgon Hexagon
	// ========================================================

	cell = GetTestingCell(47)

	DrawFilledNgon(
		map,
		cell[4],
		cell[5],
		5,
		6,
		30,
		TILE_GRASS
	)


	// ========================================================
	// TEST 48 - DrawFilledNgon Octagon
	// ========================================================

	cell = GetTestingCell(48)

	DrawFilledNgon(
		map,
		cell[4],
		cell[5],
		5,
		8,
		22.5,
		TILE_GRASS
	)

	// ========================================================
	// TEST 49 - DrawMapOntoMap
	// ========================================================

	cell = GetTestingCell(49)

	var/list/source_test_map = list()

	// Build a small 8x8 source map.
	// Everything starts as TILE_EMPTY so only the drawn
	// shape should overwrite the destination map.
	for(var/source_x = 1, source_x <= 8, source_x++)
		for(var/source_y = 1, source_y <= 8, source_y++)
			MapSet(
				source_test_map,
				source_x,
				source_y,
				TILE_EMPTY
			)

	// Draw a simple source shape.
	DrawRectangle(
		source_test_map,
		2,
		2,
		6,
		6,
		TILE_ROCKY
	)

	// Add a filled center so it's obvious the source map
	// has been copied correctly.
	DrawFilledRectangle(
		source_test_map,
		4,
		4,
		2,
		2,
		TILE_GRASS
	)

	// Stamp the source map into this test cell.
	DrawMapOntoMap(
		map,
		source_test_map,
		cell[1] + 4,
		cell[2] + 4
	)

	// ========================================================
	// TEST 50 - DrawEllipse
	// ========================================================

	cell = GetTestingCell(50)

	DrawEllipse(
		map,
		cell[4],
		cell[5],
		6,
		3,
		TILE_ROCKY
	)


	// ========================================================
	// TEST 51 - DrawFilledEllipse
	// ========================================================

	cell = GetTestingCell(51)

	DrawFilledEllipse(
		map,
		cell[4],
		cell[5],
		6,
		3,
		TILE_GRASS
	)

	// ========================================================
	// TEST 52 - ReplaceTileInRegion Before
	// ========================================================

	cell = GetTestingCell(52)

	// Draw a mixed patch:
	// rocky background with a grass rectangle in the middle.
	DrawFilledRectangle(
		map,
		cell[1] + 2,
		cell[2] + 2,
		12,
		12,
		TILE_ROCKY
	)

	DrawFilledRectangle(
		map,
		cell[1] + 4,
		cell[2] + 4,
		8,
		8,
		TILE_GRASS
	)


	// ========================================================
	// TEST 53 - ReplaceTileInRegion After
	// ========================================================

	cell = GetTestingCell(53)

	// Build the exact same starting pattern.
	DrawFilledRectangle(
		map,
		cell[1] + 2,
		cell[2] + 2,
		12,
		12,
		TILE_ROCKY
	)

	DrawFilledRectangle(
		map,
		cell[1] + 4,
		cell[2] + 4,
		8,
		8,
		TILE_GRASS
	)

	// Replace only grass tiles inside this smaller region.
	ReplaceTileInRegion(
		map,
		cell[1] + 6,
		cell[2] + 6,
		4,
		4,
		TILE_GRASS,
		TILE_DESERT
	)
	// ========================================================
	// TEST 54 - DrawCurve
	// ========================================================

	cell = GetTestingCell(54)

	DrawCurve(
		map,
		cell[1] + 1,
		cell[2] + 2,

		cell[4],
		cell[3] - 1,

		cell[1] + 14,
		cell[2] + 2,

		TILE_ROCKY
	)


	// ========================================================
	// TEST 55 - DrawThickCurve
	// ========================================================

	cell = GetTestingCell(55)

	DrawThickCurve(
		map,
		cell[1] + 1,
		cell[2] + 2,

		cell[4],
		cell[3] - 1,

		cell[1] + 14,
		cell[2] + 2,

		3,
		TILE_GRASS
	)
	// ========================================================
	// TEST 56 - DrawSine Horizontal
	// ========================================================

	cell = GetTestingCell(56)

	DrawSine(
		map,
		cell[1] + 1,
		cell[5],

		cell[1] + 14,
		cell[5],

		3,
		2,
		TILE_ROCKY
	)


	// ========================================================
	// TEST 57 - DrawSine Vertical
	// ========================================================

	cell = GetTestingCell(57)

	DrawSine(
		map,
		cell[4],
		cell[2] + 1,

		cell[4],
		cell[2] + 14,

		3,
		2,
		TILE_ROCKY
	)


	// ========================================================
	// TEST 58 - DrawSine Diagonal
	// ========================================================

	cell = GetTestingCell(58)

	DrawSine(
		map,
		cell[1] + 2,
		cell[2] + 2,

		cell[1] + 13,
		cell[2] + 13,

		3,
		2,
		TILE_ROCKY
	)


	// ========================================================
	// TEST 59 - DrawThickSine Horizontal
	// ========================================================

	cell = GetTestingCell(59)

	DrawThickSine(
		map,
		cell[1] + 1,
		cell[5],

		cell[1] + 14,
		cell[5],

		3,
		2,
		3,
		TILE_GRASS
	)


	// ========================================================
	// TEST 60 - DrawThickSine Vertical
	// ========================================================

	cell = GetTestingCell(60)

	DrawThickSine(
		map,
		cell[4],
		cell[2] + 1,

		cell[4],
		cell[2] + 14,

		3,
		2,
		3,
		TILE_GRASS
	)


	// ========================================================
	// TEST 61 - DrawThickSine Diagonal
	// ========================================================

	cell = GetTestingCell(61)

	DrawThickSine(
		map,
		cell[1] + 2,
		cell[2] + 2,

		cell[1] + 13,
		cell[2] + 13,

		3,
		2,
		3,
		TILE_GRASS
	)
	// ========================================================
	// COMMIT MAP
	// ========================================================
	// ========================================================
	// TEST 62 - DrawThickPolygon
	// ========================================================

	cell = GetTestingCell(62)

	var/list/thick_polygon_points = list(
		list(
			cell[1] + 3,
			cell[2] + 3
		),
		list(
			cell[1] + 6,
			cell[2] + 13
		),
		list(
			cell[1] + 12,
			cell[2] + 11
		),
		list(
			cell[1] + 14,
			cell[2] + 5
		),
		list(
			cell[1] + 8,
			cell[2] + 2
		)
	)

	DrawThickPolygon(
		map,
		thick_polygon_points,
		3,
		TILE_GRASS
	)

	// ========================================================
	// TESTS 63-68 - Map Rotation / Flip Helpers
	// ========================================================
	//
	// Build one asymmetric island map, then reuse that exact
	// map for every transform.
	//
	// 63 = Original
	// 64 = Rotate 90
	// 65 = Rotate 180
	// 66 = Rotate 270
	// 67 = Flip Horizontal
	// 68 = Flip Vertical
	//
	// ========================================================

	var/list/transform_test_map = list()

	// Create an intentionally asymmetric island.
	var/list/island_points = list(
		list(2, 3),
		list(3, 9),
		list(5, 13),
		list(8, 14),
		list(12, 11),
		list(11, 7),
		list(14, 4),
		list(9, 2),
		list(6, 4)
	)

	DrawFilledPolygon(
		transform_test_map,
		island_points,
		TILE_GRASS
	)

	// Add an asymmetric rocky path/feature so that rotations
	// and reflections are especially easy to recognize.
	var/list/island_path = list(
		list(4, 10),
		list(7, 8),
		list(8, 5),
		list(12, 4)
	)

	DrawPolyline(
		transform_test_map,
		island_path,
		TILE_ROCKY
	)


	// ========================================================
	// TEST 63 - Original Map
	// ========================================================

	cell = GetTestingCell(63)

	DrawMapOntoMap(
		map,
		transform_test_map,
		cell[1] + 1,
		cell[2] + 1
	)


	// ========================================================
	// TEST 64 - Rotate 90
	// ========================================================

	cell = GetTestingCell(64)

	var/list/transform_rotate_90 = RotateMap(
		transform_test_map,
		90
	)

	DrawMapOntoMap(
		map,
		transform_rotate_90,
		cell[1] + 1,
		cell[2] + 1
	)


	// ========================================================
	// TEST 65 - Rotate 180
	// ========================================================

	cell = GetTestingCell(65)

	var/list/transform_rotate_180 = RotateMap(
		transform_test_map,
		180
	)

	DrawMapOntoMap(
		map,
		transform_rotate_180,
		cell[1] + 1,
		cell[2] + 1
	)


	// ========================================================
	// TEST 66 - Rotate 270
	// ========================================================

	cell = GetTestingCell(66)

	var/list/transform_rotate_270 = RotateMap(
		transform_test_map,
		270
	)

	DrawMapOntoMap(
		map,
		transform_rotate_270,
		cell[1] + 1,
		cell[2] + 1
	)


	// ========================================================
	// TEST 67 - Flip Horizontal
	// ========================================================

	cell = GetTestingCell(67)

	var/list/transform_flip_horizontal = FlipMapHorizontal(
		transform_test_map
	)

	DrawMapOntoMap(
		map,
		transform_flip_horizontal,
		cell[1] + 1,
		cell[2] + 1
	)


	// ========================================================
	// TEST 68 - Flip Vertical
	// ========================================================

	cell = GetTestingCell(68)

	var/list/transform_flip_vertical = FlipMapVertical(
		transform_test_map
	)

	DrawMapOntoMap(
		map,
		transform_flip_vertical,
		cell[1] + 1,
		cell[2] + 1
	)
	// ========================================================
	// TEST 69 - GetPointsAroundCircle
	// ========================================================

	cell = GetTestingCell(69)

	var/test_radius = 6

	// Draw the reference circle.
	DrawCircle(
		map,
		cell[4],
		cell[5],
		test_radius,
		TILE_ROCKY
	)

	// Pick random unique points from the same circle edge.
	var/list/random_circle_points = GetPointsAroundCircle(
		cell[4],
		cell[5],
		test_radius,
		8
	)

	// Mark selected points as desert.
	for(var/list/point in random_circle_points)
		MapSet(
			map,
			point[1],
			point[2],
			TILE_DESERT
		)


	// ========================================================
	// TEST 70 - GetEvenPointsAroundCircle
	// ========================================================

	cell = GetTestingCell(70)

	// Draw the same reference circle.
	DrawCircle(
		map,
		cell[4],
		cell[5],
		test_radius,
		TILE_ROCKY
	)

	// Pick approximately evenly distributed points from
	// around the same circle edge.
	var/list/even_circle_points = GetEvenPointsAroundCircle(
		cell[4],
		cell[5],
		test_radius,
		8
	)

	// Mark selected points as desert.
	for(var/list/point in even_circle_points)
		MapSet(
			map,
			point[1],
			point[2],
			TILE_DESERT
		)

	// ========================================================
	// Commit all tests to the map
	// ========================================================
	CommitTestingMap(map)

	// ========================================================
	// CLICKABLE TEST LABELS
	// ========================================================

	AddTestingLabel(1,  "DrawPixel")
	AddTestingLabel(2,  "DrawHorizontalLine")
	AddTestingLabel(3,  "DrawVerticalLine")
	AddTestingLabel(4,  "DrawLine")
	AddTestingLabel(5,  "DrawArc")
	AddTestingLabel(6,  "PaintFill")
	AddTestingLabel(7,  "DrawCircle")
	AddTestingLabel(8,  "DrawFilledCircle")
	AddTestingLabel(9,  "DrawRectangle")
	AddTestingLabel(10, "DrawFilledRectangle")
	AddTestingLabel(11, "DrawTriangle")
	AddTestingLabel(12, "DrawFilledTriangle")
	AddTestingLabel(13, "DrawHexagon")
	AddTestingLabel(14, "DrawFilledHexagon")
	AddTestingLabel(15, "DrawThickCircle")
	AddTestingLabel(16, "DrawThickCircleInner")
	AddTestingLabel(17, "DrawThickCircleOuter")
	AddTestingLabel(18, "DrawSquare")
	AddTestingLabel(19, "DrawFilledSquare")
	AddTestingLabel(20, "DrawThickSquare")
	AddTestingLabel(21, "DrawThickRectangle")
	AddTestingLabel(22, "DrawRoundedRectangle")
	AddTestingLabel(23, "DrawFilledRoundedRectangle")
	AddTestingLabel(24, "DrawRoundedSquare")
	AddTestingLabel(25, "DrawFilledRoundedSquare")
	AddTestingLabel(26, "DrawLobedTriangle")
	AddTestingLabel(27, "DrawFilledLobedTriangle")
	AddTestingLabel(28, "DrawLobedHexagon")
	AddTestingLabel(29, "DrawFilledLobedHexagon")
	AddTestingLabel(30, "DrawRoundedTriangle")
	AddTestingLabel(31, "DrawThickLine - 1")
	AddTestingLabel(32, "DrawThickLine - 3")
	AddTestingLabel(33, "DrawThickLine - 5")
	AddTestingLabel(34, "DrawThickLine - 7")
	AddTestingLabel(35, "DrawPolyline")
	AddTestingLabel(36, "DrawThickPolyline")
	AddTestingLabel(37, "DrawPolygon")
	AddTestingLabel(38, "DrawFilledPolygon")
	AddTestingLabel(39, "DrawNgon - Triangle")
	AddTestingLabel(40, "DrawNgon - Square")
	AddTestingLabel(41, "DrawNgon - Pentagon")
	AddTestingLabel(42, "DrawNgon - Hexagon")
	AddTestingLabel(43, "DrawNgon - Octagon")
	AddTestingLabel(44, "DrawFilledNgon - Triangle")
	AddTestingLabel(45, "DrawFilledNgon - Square")
	AddTestingLabel(46, "DrawFilledNgon - Pentagon")
	AddTestingLabel(47, "DrawFilledNgon - Hexagon")
	AddTestingLabel(48, "DrawFilledNgon - Octagon")
	AddTestingLabel(49, "DrawMapOntoMap")
	AddTestingLabel(50, "DrawEllipse")
	AddTestingLabel(51, "DrawFilledEllipse")
	AddTestingLabel(52, "ReplaceTileInRegion - Before")
	AddTestingLabel(53, "ReplaceTileInRegion - After")
	AddTestingLabel(54, "DrawCurve")
	AddTestingLabel(55, "DrawThickCurve")
	AddTestingLabel(56, "DrawSine - Horizontal")
	AddTestingLabel(57, "DrawSine - Vertical")
	AddTestingLabel(58, "DrawSine - Diagonal")
	AddTestingLabel(59, "DrawThickSine - Horizontal")
	AddTestingLabel(60, "DrawThickSine - Vertical")
	AddTestingLabel(61, "DrawThickSine - Diagonal")
	AddTestingLabel(62, "DrawThickPolygon")
	AddTestingLabel(63, "Map Transform - Original")
	AddTestingLabel(64, "RotateMap - 90")
	AddTestingLabel(65, "RotateMap - 180")
	AddTestingLabel(66, "RotateMap - 270")
	AddTestingLabel(67, "FlipMap - Horizontal")
	AddTestingLabel(68, "FlipMap - Vertical")
	AddTestingLabel(69, "Circle Points - Random")
	AddTestingLabel(70, "Circle Points - Even")
	world << "Drawing test map generated: 70 tests."


// ============================================================
// GENERATE TESTING MAP VERB
// ============================================================

mob/verb/GenerateTestingMap()
	set name = "Generate Testing Map"
	set category = "Testing"

	world.GenerateTestingMap()
	src.loc = locate(1,256,1)


mob/verb/GenerateMaze()
	set name = "Generate ZMaze Test"
	set category = "Testing"
	world.MazeTest()
	src.loc = locate(128, 128, 1)

world/proc/MazeTest()

	var/list/map = list()

	// Fill the entire generated map with ocean.
	for(var/x = 1, x <= TEST_MAP_SIZE, x++)
		for(var/y = 1, y <= TEST_MAP_SIZE, y++)
			MapSet(map, x, y, TILE_OCEAN)

	var/list/result = world.DrawForestMazePath(
	map,
	20,                 // top-left X
	230,                // top-left Y
	180,                // maximum tile width
	160,                // maximum tile height
	TILE_GRASS,
	TILE_ROCKY,
	3,
	null,
	null,
	null,
	null,
	15
	)

	world.CommitForestMazeTrees(
	result["trees"],
	1
	)

	CommitTestingMap(map)