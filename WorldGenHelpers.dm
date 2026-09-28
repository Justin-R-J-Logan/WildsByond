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

// ============================================================
// GET POINTS AROUND CIRCLE
// ============================================================
//
// Returns a list of unique random points located on the edge
// of a circle.
//
// The circle edge is generated using the same midpoint-circle
// logic as DrawCircle(), keeping the returned points
// consistent with the rasterized circle shape.
//
// cx / cy:
//     Center of the circle.
//
// radius:
//     Circle radius.
//
// point_count:
//     Maximum number of unique points to return.
//
// If point_count is greater than the number of available edge
// tiles, all available edge tiles are returned.
//
// Returned format:
//
//     list(
//         list(x, y),
//         list(x, y),
//         ...
//     )
//
// ============================================================

world/proc/GetPointsAroundCircle(
	var/cx,
	var/cy,
	var/radius,
	var/point_count
)
	var/list/edge_points = list()

	if(radius < 0 || point_count <= 0)
		return edge_points

	if(radius == 0)
		edge_points += list(
			list(cx, cy)
		)
		return edge_points


	// --------------------------------------------------------
	// Build the circle edge using the midpoint circle algorithm.
	// --------------------------------------------------------

	var/x = radius
	var/y = 0
	var/decision = 1 - radius

	while(x >= y)

		var/list/candidates = list(
			list(cx + x, cy + y),
			list(cx - x, cy + y),
			list(cx + x, cy - y),
			list(cx - x, cy - y),

			list(cx + y, cy + x),
			list(cx - y, cy + x),
			list(cx + y, cy - x),
			list(cx - y, cy - x)
		)

		// Some symmetry positions overlap when x == y
		// or y == 0, so make sure each coordinate is added
		// only once.

		for(var/list/point in candidates)

			var/point_x = point[1]
			var/point_y = point[2]

			var/already_exists = FALSE

			for(var/list/existing in edge_points)
				if(existing[1] == point_x && existing[2] == point_y)
					already_exists = TRUE
					break

			if(!already_exists)
				edge_points += list(
					list(point_x, point_y)
				)

		y++

		if(decision <= 0)
			decision += (2 * y) + 1

		else
			x--
			decision += (2 * (y - x)) + 1


	// --------------------------------------------------------
	// Randomly select unique points from the edge.
	//
	// Remove selected entries from the available list so
	// duplicates cannot be returned.
	// --------------------------------------------------------

	var/list/results = list()

	point_count = min(
		point_count,
		edge_points.len
	)

	for(var/i = 1, i <= point_count, i++)

		var/index = rand(
			1,
			edge_points.len
		)

		var/list/point = edge_points[index]

		results += list(
			list(
				point[1],
				point[2]
			)
		)

		edge_points.Cut(
			index,
			index + 1
		)

	return results

// ============================================================
// GET EVEN POINTS AROUND CIRCLE
// ============================================================
//
// Returns a list of unique points located around the edge
// of a circle, distributed approximately evenly.
//
// The circle edge is generated using the same midpoint-circle
// logic as DrawCircle(), keeping the returned points
// consistent with the rasterized circle shape.
//
// Unlike GetPointsAroundCircle(), this proc divides the circle
// edge into sections and selects one random point from each
// section.
//
// This prevents returned points from clustering heavily on
// one side of the circle while still preserving some
// randomness.
//
// Returned format:
//
//     list(
//         list(x, y),
//         list(x, y),
//         ...
//     )
//
// ============================================================

world/proc/GetEvenPointsAroundCircle(
	var/cx,
	var/cy,
	var/radius,
	var/point_count
)
	var/list/edge_points = list()

	if(radius < 0 || point_count <= 0)
		return edge_points

	if(radius == 0)
		edge_points += list(
			list(cx, cy)
		)
		return edge_points


	// --------------------------------------------------------
	// Generate the same midpoint-circle edge used by
	// DrawCircle().
	// --------------------------------------------------------

	var/x = radius
	var/y = 0
	var/decision = 1 - radius

	while(x >= y)

		var/list/candidates = list(
			list(cx + x, cy + y),
			list(cx - x, cy + y),
			list(cx + x, cy - y),
			list(cx - x, cy - y),

			list(cx + y, cy + x),
			list(cx - y, cy + x),
			list(cx + y, cy - x),
			list(cx - y, cy - x)
		)

		for(var/list/point in candidates)

			var/point_x = point[1]
			var/point_y = point[2]

			var/already_exists = FALSE

			for(var/list/existing in edge_points)
				if(existing[1] == point_x && existing[2] == point_y)
					already_exists = TRUE
					break

			if(!already_exists)
				edge_points += list(
					list(point_x, point_y)
				)

		y++

		if(decision <= 0)
			decision += (2 * y) + 1

		else
			x--
			decision += (2 * (y - x)) + 1


	// --------------------------------------------------------
	// Cannot return more unique points than exist.
	// --------------------------------------------------------

	point_count = min(
		point_count,
		edge_points.len
	)


	// --------------------------------------------------------
	// Attach an angle to each edge point.
	//
	// BYOND's arctan(y, x) gives us the angle around the
	// center. Normalize negative angles into 0-360.
	// --------------------------------------------------------

	var/list/angular_points = list()

	for(var/list/point in edge_points)

		var/dx = point[1] - cx
		var/dy = point[2] - cy

		var/angle = arctan(dy, dx)

		if(angle < 0)
			angle += 360

		angular_points += list(
			list(
				"x" = point[1],
				"y" = point[2],
				"angle" = angle
			)
		)


	// --------------------------------------------------------
	// Sort points by angle.
	//
	// Simple insertion sort is fine here because circle edges
	// are relatively small.
	// --------------------------------------------------------

	for(var/i = 2, i <= angular_points.len, i++)

		var/list/current = angular_points[i]
		var/j = i - 1

		while(j >= 1 && angular_points[j]["angle"] > current["angle"])
			angular_points[j + 1] = angular_points[j]
			j--

		angular_points[j + 1] = current


	// --------------------------------------------------------
	// Divide the ordered circle edge into roughly equal
	// sections and choose one random point from each section.
	// --------------------------------------------------------

	var/list/results = list()

	for(var/i = 1, i <= point_count, i++)

		var/start_index = floor(
			((i - 1) * angular_points.len) / point_count
		) + 1

		var/end_index = floor(
			(i * angular_points.len) / point_count
		)

		if(end_index < start_index)
			end_index = start_index

		var/chosen_index = rand(
			start_index,
			end_index
		)

		var/list/chosen = angular_points[chosen_index]

		results += list(
			list(
				chosen["x"],
				chosen["y"]
			)
		)

	return results

// ============================================================
// COMBINE UNIQUE POINT LISTS
// ============================================================
//
// Combines two lists of coordinate points into one list,
// removing any duplicate coordinates.
//
// Expected point format:
//
//     list(
//         list(x, y),
//         list(x, y),
//         ...
//     )
//
// Points are considered duplicates when both their X and Y
// coordinates match.
//
// The original lists are not modified.
//
// ============================================================

world/proc/CombineUniquePointLists(
	var/list/list_a,
	var/list/list_b
)
	var/list/result = list()

	if(list_a)
		for(var/list/point in list_a)

			if(!point || point.len < 2)
				continue

			var/point_x = point[1]
			var/point_y = point[2]

			var/already_exists = FALSE

			for(var/list/existing in result)
				if(existing[1] == point_x && existing[2] == point_y)
					already_exists = TRUE
					break

			if(!already_exists)
				result += list(
					list(
						point_x,
						point_y
					)
				)


	if(list_b)
		for(var/list/point in list_b)

			if(!point || point.len < 2)
				continue

			var/point_x = point[1]
			var/point_y = point[2]

			var/already_exists = FALSE

			for(var/list/existing in result)
				if(existing[1] == point_x && existing[2] == point_y)
					already_exists = TRUE
					break

			if(!already_exists)
				result += list(
					list(
						point_x,
						point_y
					)
				)

	return result