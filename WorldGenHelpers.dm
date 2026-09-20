// ============================================================
// MAP HELPER FUNCTIONS
// ============================================================
//
// These functions provide a common interface for working with
// our generated map data.
//
// The generator operates entirely on lists rather than actual
// BYOND turfs. This keeps map generation separate from the
// relatively expensive process of creating/changing turfs.
//
// Map coordinates are stored using the format:
//     "x,y"
//
// Example:
//     MapSet(landmap, 10, 15, TILE_LAND)
//     MapGet(landmap, 10, 15)
//
// Lists are reference types in DM, so MapSet() can modify the
// supplied map directly.
//


// ============================================================
// MAP KEY
// ============================================================
//
// Converts X/Y coordinates into the string used as a key in
// our associative map lists.
//
// Example:
//     MapKey(10, 15)
//     returns "10,15"
//

world/proc/MapKey(var/x, var/y)
	return "[x],[y]"


// ============================================================
// MAP GET
// ============================================================
//
// Retrieves the value stored at a specific coordinate.
//
// Example:
//     var/tile = MapGet(landmap, 10, 15)
//

world/proc/MapGet(var/list/map, var/x, var/y)
	return map[MapKey(x, y)]


// ============================================================
// MAP SET
// ============================================================
//
// Sets the value at a specific coordinate.
//
// Because lists are reference types in DM, changes made here
// are made to the original map passed into the proc.
//
// Example:
//     MapSet(landmap, 10, 15, TILE_LAND)
//

world/proc/MapSet(var/list/map, var/x, var/y, var/value)
	map[MapKey(x, y)] = value


// ============================================================
// MAP HAS
// ============================================================
//
// Checks whether a coordinate has an entry in the map.
//
// This is useful when we need to distinguish between a tile
// that does not exist and a tile whose value happens to be 0.
//
// Example:
//     if(MapHas(landmap, 10, 15))
//         // Coordinate exists in the map.
//

world/proc/MapHas(var/list/map, var/x, var/y)
	return MapKey(x, y) in map


// ============================================================
// MAP IN BOUNDS
// ============================================================
//
// Checks whether a coordinate exists within the generated map.
//
// This prevents generation algorithms from attempting to work
// outside the edges of the world.
//
// Example:
//     if(MapInBounds(x + 1, y))
//         // The tile to the east exists.
//

world/proc/MapInBounds(var/x, var/y)
	if(x < 1 || x > world.maxx)
		return FALSE

	if(y < 1 || y > world.maxy)
		return FALSE

	return TRUE


// ============================================================
// MAP NEIGHBOURS
// ============================================================
//
// Returns the four cardinal neighbours surrounding a tile.
//
// The returned list contains coordinate pairs in this format:
//
//     list(
//         list(x + 1, y),
//         list(x - 1, y),
//         list(x, y + 1),
//         list(x, y - 1)
//     )
//
// Coordinates outside the map are automatically excluded.
//
// Diagonal neighbours are intentionally NOT included.
//
// Example:
//
//     var/list/neighbours = MapNeighbours(x, y)
//
//     for(var/list/position in neighbours)
//         var/nx = position[1]
//         var/ny = position[2]
//
//         // Work with nx/ny here.
//

world/proc/MapNeighbours(var/x, var/y)
	var/list/neighbours = list()

	// East
	if(MapInBounds(x + 1, y))
		neighbours += list(list(x + 1, y))

	// West
	if(MapInBounds(x - 1, y))
		neighbours += list(list(x - 1, y))

	// North
	if(MapInBounds(x, y + 1))
		neighbours += list(list(x, y + 1))

	// South
	if(MapInBounds(x, y - 1))
		neighbours += list(list(x, y - 1))

	return neighbours