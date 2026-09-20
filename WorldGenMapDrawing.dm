// ============================================================
// MAP DRAWING - CORE PRIMITIVES
// ============================================================
//
// These functions draw directly onto the generated map lists.
//
// They do NOT create or modify BYOND turfs.
//
// All drawing functions use MapSet() so that the underlying
// map representation remains abstracted away from the drawing
// code.
//
// Core primitives:
//
//     DrawPixel()
//     DrawHorizontalLine()
//     DrawVerticalLine()
//     DrawLine()
//     DrawCircle()
//     DrawFilledCircle()
//     DrawRectangle()
//     DrawFilledRectangle()
//     DrawTriangle()
//     DrawFilledTriangle()
//     DrawHexagon()
//     DrawFilledHexagon()
//
// Coordinate conventions:
//
//     Circles / hexagons:
//         x/y = center
//
//     Rectangles:
//         x/y = top-left corner
//
//     Triangles:
//         x/y = center of the base
//         base = width of the base
//         height = height of the triangle
//
// ============================================================



// ============================================================
// DRAW PIXEL
// ============================================================
//
// Draws a single tile at the specified coordinate.
//
// This is the most basic drawing primitive and is useful both
// directly and as a building block for more complicated shapes.
//
// Example:
//
//     DrawPixel(landmap, 10, 15, TILE_LAND)
//

world/proc/DrawPixel(var/list/map, var/x, var/y, var/tile)

	if(!MapInBounds(x, y))
		return

	MapSet(map, x, y, tile)



// ============================================================
// DRAW HORIZONTAL LINE
// ============================================================
//
// Draws a horizontal line beginning at x/y and extending for
// the specified width.
//
// Example:
//
//     DrawHorizontalLine(map, 10, 20, 15, TILE_LAND)
//
// This draws from:
//
//     x = 10
//     through
//     x = 24
//
// because width represents the number of tiles drawn.
//
// ============================================================

world/proc/DrawHorizontalLine(
	var/list/map,
	var/x,
	var/y,
	var/width,
	var/tile
)

	if(width <= 0)
		return

	for(var/i = 0, i < width, i++)

		var/draw_x = x + i

		if(MapInBounds(draw_x, y))
			MapSet(map, draw_x, y, tile)



// ============================================================
// DRAW VERTICAL LINE
// ============================================================
//
// Draws a vertical line beginning at x/y and extending for
// the specified height.
//
// Example:
//
//     DrawVerticalLine(map, 10, 20, 15, TILE_LAND)
//
// This draws from:
//
//     y = 20
//     through
//     y = 34
//
// because height represents the number of tiles drawn.
//
// ============================================================

world/proc/DrawVerticalLine(
	var/list/map,
	var/x,
	var/y,
	var/height,
	var/tile
)

	if(height <= 0)
		return

	for(var/i = 0, i < height, i++)

		var/draw_y = y + i

		if(MapInBounds(x, draw_y))
			MapSet(map, x, draw_y, tile)



// ============================================================
// DRAW LINE
// ============================================================
//
// Draws a line between two coordinates using Bresenham's line
// algorithm.
//
// This produces a continuous line using only integer tile
// coordinates, making it well suited for our map generator.
//
// Example:
//
//     DrawLine(map, 10, 10, 30, 20, TILE_ROCKY)
//
// Draws a line from:
//
//     (10,10)
//         to
//     (30,20)
//
// ============================================================

world/proc/DrawLine(
	var/list/map,
	var/x1,
	var/y1,
	var/x2,
	var/y2,
	var/tile
)

	var/dx = abs(x2 - x1)
	var/dy = abs(y2 - y1)

	var/sx = 1
	var/sy = 1

	if(x1 > x2)
		sx = -1

	if(y1 > y2)
		sy = -1

	var/err = dx - dy

	while(TRUE)

		DrawPixel(map, x1, y1, tile)

		if(x1 == x2 && y1 == y2)
			break

		var/e2 = 2 * err

		if(e2 > -dy)
			err -= dy
			x1 += sx

		if(e2 < dx)
			err += dx
			y1 += sy

// ============================================================
// DRAW ARC
// ============================================================
//
// Draws an arc between two points with specified angles.
//
// This produces a continuous line using only integer tile
// coordinates, making it well suited for our map generator.
//
// Example:
//
//     DrawLine(map, 10, 10, 30, 20, TILE_ROCKY)
//
// Draws a line from:
//
//     (10,10)
//         to
//     (30,20)
//
// ============================================================

world/proc/DrawArc(
	var/list/map,
	var/cx,
	var/cy,
	var/radius,
	var/start_angle,
	var/end_angle,
	var/tile
)
	// A negative radius doesn't make sense.
	if(radius < 0)
		return

	// A radius of zero is just a single pixel.
	if(radius == 0)
		DrawPixel(map, cx, cy, tile)
		return

	// Calculate the sweep of the arc.
	// Angles increase counter-clockwise.
	var/sweep = end_angle - start_angle

	// Allow arcs to cross the 0-degree boundary.
	while(sweep < 0)
		sweep += 360

	// If start and end are identical, treat it as a full circle.
	if(sweep == 0)
		sweep = 360

	// Choose enough points that the arc won't have gaps.
	// About 45 degrees of arc per tile of radius gives
	// roughly one tile or less between samples.
	var/segments = max(1, round((sweep * radius) / 45))

	// Calculate the first point.
	var/angle = start_angle
	var/last_x = round(cx + cos(angle) * radius)
	var/last_y = round(cy + sin(angle) * radius)

	// Draw each successive point and connect it to the previous one.
	for(var/i = 1, i <= segments, i++)
		angle = start_angle + (sweep * i / segments)

		var/draw_x = round(cx + cos(angle) * radius)
		var/draw_y = round(cy + sin(angle) * radius)

		// Connecting the samples prevents gaps in the arc.
		DrawLine(map, last_x, last_y, draw_x, draw_y, tile)

		last_x = draw_x
		last_y = draw_y

// ============================================================
// PAINT FILL
// ============================================================
//
// Paints the inside of a shape (or the whole map) with the
// selected tile
//
// x/y represents the center of the fill.
//
//
// Example:
//
//     PaintFill(map, 50, 50, TILE_BEACH)
//
// ============================================================

world/proc/PaintFill(
	var/list/map,
	var/start_x,
	var/start_y,
	var/tile
)
	// Make sure the starting point is inside the map.
	if(!MapInBounds(start_x, start_y))
		return

	// Remember what we're replacing.
	var/source_tile = MapGet(map, start_x, start_y)

	// If the source and destination are identical,
	// there is nothing to do.
	if(source_tile == tile)
		return

	// Queue of positions that still need to be checked.
	var/list/frontier = list()

	// Add the starting position.
	frontier += list(list(start_x, start_y))

	// Process the frontier until there are no more connected tiles.
	while(frontier.len)
		// Take the first position from the queue.
		var/list/position = frontier[1]
		frontier.Cut(1, 2)

		var/x = position[1]
		var/y = position[2]

		// The tile may already have been changed by another
		// iteration, so only process tiles that still match
		// the original source tile.
		if(MapGet(map, x, y) != source_tile)
			continue

		// Replace this tile.
		MapSet(map, x, y, tile)

		// Check all four cardinal neighbours.
		var/list/neighbours = MapNeighbours(x, y)

		for(var/list/neighbour in neighbours)
			var/nx = neighbour[1]
			var/ny = neighbour[2]

			// Only add tiles that still match the source.
			if(MapGet(map, nx, ny) == source_tile)
				frontier += list(list(nx, ny))

// ============================================================
// DRAW CIRCLE
// ============================================================
//
// Draws the OUTLINE of a circle.
//
// x/y represents the center of the circle.
//
// radius represents the distance from the center to the
// outer edge.
//
// The circle is rasterized onto the tile grid, so it will not
// be mathematically perfect at small radii. This is expected
// for a tile-based map.
//
// Example:
//
//     DrawCircle(map, 50, 50, 10, TILE_BEACH)
//
// ============================================================

world/proc/DrawCircle(
	var/list/map,
	var/cx,
	var/cy,
	var/radius,
	var/tile
)

	if(radius < 0)
		return

	var/x = radius
	var/y = 0
	var/decision = 1 - radius

	while(x >= y)

		// Eight-way symmetry
		DrawPixel(map, cx + x, cy + y, tile)
		DrawPixel(map, cx + y, cy + x, tile)
		DrawPixel(map, cx - y, cy + x, tile)
		DrawPixel(map, cx - x, cy + y, tile)

		DrawPixel(map, cx - x, cy - y, tile)
		DrawPixel(map, cx - y, cy - x, tile)
		DrawPixel(map, cx + y, cy - x, tile)
		DrawPixel(map, cx + x, cy - y, tile)

		y++

		if(decision <= 0)
			decision += 2 * y + 1
		else
			x--
			decision += 2 * (y - x) + 1



// ============================================================
// DRAW FILLED CIRCLE
// ============================================================
//
// Draws a filled circle.
//
// Unlike DrawCircle(), this fills the entire area inside the
// circle.
//
// x/y represents the center.
//
// radius represents the distance from the center to the
// outer edge.
//
// Example:
//
//     DrawFilledCircle(map, 50, 50, 10, TILE_LAND)
//
// ============================================================

world/proc/DrawFilledCircle(
	var/list/map,
	var/cx,
	var/cy,
	var/radius,
	var/tile
)

	if(radius < 0)
		return

	// Draw each horizontal scanline across the circle.
	for(var/y = -radius, y <= radius, y++)

		var/width = sqrt((radius * radius) - (y * y))

		var/start_x = round(cx - width)
		var/end_x = round(cx + width)

		for(var/x = start_x, x <= end_x, x++)

			if(MapInBounds(x, cy + y))
				MapSet(map, x, cy + y, tile)



// ============================================================
// DRAW RECTANGLE
// ============================================================
//
// Draws the OUTLINE of a rectangle.
//
// x/y represents the top-left corner.
//
// width and height represent the number of tiles occupied.
//
// Example:
//
//     DrawRectangle(map, 10, 10, 20, 15, TILE_ROCKY)
//
// ============================================================

world/proc/DrawRectangle(
	var/list/map,
	var/x,
	var/y,
	var/width,
	var/height,
	var/tile
)

	if(width <= 0 || height <= 0)
		return

	// Top edge
	DrawHorizontalLine(map, x, y, width, tile)

	// Bottom edge
	DrawHorizontalLine(map, x, y + height - 1, width, tile)

	// Left edge
	DrawVerticalLine(map, x, y, height, tile)

	// Right edge
	DrawVerticalLine(map, x + width - 1, y, height, tile)



// ============================================================
// DRAW FILLED RECTANGLE
// ============================================================
//
// Draws a completely filled rectangle.
//
// x/y represents the top-left corner.
//
// width and height represent the number of tiles occupied.
//
// Example:
//
//     DrawFilledRectangle(map, 10, 10, 20, 15, TILE_GRASS)
//
// ============================================================

world/proc/DrawFilledRectangle(
	var/list/map,
	var/x,
	var/y,
	var/width,
	var/height,
	var/tile
)

	if(width <= 0 || height <= 0)
		return

	for(var/draw_y = y, draw_y < y + height, draw_y++)

		DrawHorizontalLine(
			map,
			x,
			draw_y,
			width,
			tile
		)



// ============================================================
// DRAW TRIANGLE
// ============================================================
//
// Draws the OUTLINE of an upward-facing triangle.
//
// x/y represents the CENTER of the triangle's base.
//
// base represents the width of the base.
//
// height represents the height of the triangle.
//
// Example:
//
//     DrawTriangle(map, 50, 20, 15, 10, TILE_ROCKY)
//
// The base will be centered around x/y and the point of the
// triangle will extend upward.
//
// ============================================================

world/proc/DrawTriangle(
	var/list/map,
	var/cx,
	var/y,
	var/base,
	var/height,
	var/tile
)

	if(base <= 0 || height <= 0)
		return

	var/left_x = round(cx - (base / 2))
	var/right_x = round(cx + (base / 2))
	var/top_y = y + height - 1

	// Base
	DrawLine(
		map,
		left_x,
		y,
		right_x,
		y,
		tile
	)

	// Left side
	DrawLine(
		map,
		left_x,
		y,
		cx,
		top_y,
		tile
	)

	// Right side
	DrawLine(
		map,
		right_x,
		y,
		cx,
		top_y,
		tile
	)



// ============================================================
// DRAW FILLED TRIANGLE
// ============================================================
//
// Draws a completely filled upward-facing triangle.
//
// x/y represents the CENTER of the triangle's base.
//
// base represents the width of the base.
//
// height represents the height of the triangle.
//
// The triangle is filled using horizontal scanlines.
//
// ============================================================


// ============================================================
// FILLED TRIANGLE
// ============================================================
//
// Draws a filled triangle.
//
// x/y convention:
//
//     x = center of the base
//     y = bottom/base of the triangle
//
// The triangle grows to its full base width at y, then
// progressively narrows toward the point at the top.
//
// ============================================================

world/proc/DrawFilledTriangle(
	var/list/map,
	var/cx,
	var/y,
	var/base,
	var/height,
	var/tile
)
	if(base <= 0 || height <= 0)
		return

	// Special case for a one-tile-high triangle.
	if(height == 1)
		DrawPixel(
			map,
			cx,
			y,
			tile
		)
		return

	for(var/i = 0, i < height, i++)
		// Progress goes from 0 at the base to 1 at the top.
		var/progress = i / (height - 1)

		// Start at the full base width and narrow toward
		// the point.
		var/half_width = (base / 2) * (1 - progress)

		var/start_x = round(cx - half_width)
		var/end_x = round(cx + half_width)

		var/draw_y = y + i

		for(var/x = start_x, x <= end_x, x++)
			if(MapInBounds(x, draw_y))
				MapSet(map, x, draw_y, tile)




// ============================================================
// DRAW HEXAGON
// ============================================================
//
// Draws the OUTLINE of a regular point-top hexagon.
//
// x/y represents the center.
//
// radius represents the distance from the center to a vertex.
//
// The hexagon is constructed from six straight line segments.
//
// Example:
//
//     DrawHexagon(map, 50, 50, 10, TILE_ROCKY)
//
// ============================================================

world/proc/DrawHexagon(
	var/list/map,
	var/cx,
	var/cy,
	var/radius,
	var/tile
)

	if(radius <= 0)
		return

	// Point-top hexagon vertices.
	//
	// Using the standard hexagonal proportions:
	//
	//     top
	//      /\
	//     /  \
	//     \  /
	//      \/
	//
	// Since we're working with integer tiles, the coordinates
	// are rounded to the nearest tile.

	var/x1 = cx
	var/y1 = cy + radius

	var/x2 = round(cx + (radius * 0.866))
	var/y2 = round(cy + (radius * 0.5))

	var/x3 = round(cx + (radius * 0.866))
	var/y3 = round(cy - (radius * 0.5))

	var/x4 = cx
	var/y4 = cy - radius

	var/x5 = round(cx - (radius * 0.866))
	var/y5 = round(cy - (radius * 0.5))

	var/x6 = round(cx - (radius * 0.866))
	var/y6 = round(cy + (radius * 0.5))

	// Six sides
	DrawLine(map, x1, y1, x2, y2, tile)
	DrawLine(map, x2, y2, x3, y3, tile)
	DrawLine(map, x3, y3, x4, y4, tile)
	DrawLine(map, x4, y4, x5, y5, tile)
	DrawLine(map, x5, y5, x6, y6, tile)
	DrawLine(map, x6, y6, x1, y1, tile)



// ============================================================
// DRAW FILLED HEXAGON
// ============================================================
//
// Draws a completely filled regular point-top hexagon.
//
// x/y represents the center.
//
// radius represents the distance from the center to a vertex.
//
// The shape is filled using horizontal scanlines.
//
// ============================================================

world/proc/DrawFilledHexagon(
	var/list/map,
	var/cx,
	var/cy,
	var/radius,
	var/tile
)

	if(radius <= 0)
		return

	// A point-top hexagon can be divided into three vertical
	// sections:
	//
	//     upper taper
	//     full-width middle
	//     lower taper
	//
	// We calculate the horizontal width available at each Y.

	for(var/y = -radius, y <= radius, y++)

		var/abs_y = abs(y)
		var/width

		if(abs_y <= round(radius / 2))
			// Middle section
			width = radius
		else
			// Tapering section
			var/distance = abs_y - round(radius / 2)
			width = radius - round(distance * 1.732)

		if(width < 0)
			width = 0

		var/start_x = round(cx - width)
		var/end_x = round(cx + width)

		for(var/x = start_x, x <= end_x, x++)

			if(MapInBounds(x, cy + y))
				MapSet(map, x, cy + y, tile)


// ============================================================
// MAP DRAWING - PASS 2
// ============================================================
//
// Thickness and basic convenience shapes.
//
// These functions build on the core drawing primitives from
// Pass 1.
//
// Thickness functions draw outlines/rings only. If a filled
// shape with a thicker border is needed, simply draw the thick
// shape first and then draw the filled shape over/inside it.
//
// Added in this pass:
//
//     DrawThickCircle()
//     DrawThickCircleInner()
//     DrawThickCircleOuter()
//
//     DrawSquare()
//     DrawFilledSquare()
//     DrawThickSquare()
//
//     DrawThickRectangle()
//
// ============================================================


// ============================================================
// THICK CIRCLE
// ============================================================
//
// Draws a ring centered around the specified radius.
//
// The radius represents the approximate centerline of the
// ring. Thickness is distributed approximately evenly between
// the inside and outside of the radius.
//
// Example:
//
//     DrawThickCircle(map, 64, 64, 20, 3, TILE_ROCKY)
//
// ============================================================

world/proc/DrawThickCircle(
	var/list/map,
	var/cx,
	var/cy,
	var/radius,
	var/thickness,
	var/tile
)
	if(radius < 0 || thickness <= 0)
		return

	var/inner_radius = max(0, radius - round(thickness / 2))
	var/outer_radius = radius + round(thickness / 2)

	for(var/r = inner_radius, r <= outer_radius, r++)
		DrawCircle(map, cx, cy, r, tile)


// ============================================================
// THICK CIRCLE - INNER
// ============================================================
//
// Draws a ring where the supplied radius is the OUTER radius.
//
// Thickness extends inward from the specified radius.
//
// Example:
//
//     DrawThickCircleInner(map, 64, 64, 20, 4, TILE_ROCKY)
//
// This produces a ring from approximately radius 16 to 20.
//
// ============================================================

world/proc/DrawThickCircleInner(
	var/list/map,
	var/cx,
	var/cy,
	var/radius,
	var/thickness,
	var/tile
)
	if(radius < 0 || thickness <= 0)
		return

	var/inner_radius = max(0, radius - thickness)

	for(var/r = inner_radius, r <= radius, r++)
		DrawCircle(map, cx, cy, r, tile)


// ============================================================
// THICK CIRCLE - OUTER
// ============================================================
//
// Draws a ring where the supplied radius is the INNER radius.
//
// Thickness extends outward from the specified radius.
//
// Example:
//
//     DrawThickCircleOuter(map, 64, 64, 20, 4, TILE_ROCKY)
//
// This produces a ring from approximately radius 20 to 24.
//
// ============================================================

world/proc/DrawThickCircleOuter(
	var/list/map,
	var/cx,
	var/cy,
	var/radius,
	var/thickness,
	var/tile
)
	if(radius < 0 || thickness <= 0)
		return

	var/outer_radius = radius + thickness

	for(var/r = radius, r <= outer_radius, r++)
		DrawCircle(map, cx, cy, r, tile)


// ============================================================
// SQUARE
// ============================================================
//
// Convenience wrapper around DrawRectangle().
//
// x/y represent the top-left corner.
//
// ============================================================

world/proc/DrawSquare(
	var/list/map,
	var/x,
	var/y,
	var/size,
	var/tile
)
	if(size <= 0)
		return

	DrawRectangle(
		map,
		x,
		y,
		size,
		size,
		tile
	)


// ============================================================
// FILLED SQUARE
// ============================================================
//
// Convenience wrapper around DrawFilledRectangle().
//
// x/y represent the top-left corner.
//
// ============================================================

world/proc/DrawFilledSquare(
	var/list/map,
	var/x,
	var/y,
	var/size,
	var/tile
)
	if(size <= 0)
		return

	DrawFilledRectangle(
		map,
		x,
		y,
		size,
		size,
		tile
	)


// ============================================================
// THICK SQUARE
// ============================================================
//
// Convenience wrapper around DrawThickRectangle().
//
// x/y represent the top-left corner.
//
// ============================================================

world/proc/DrawThickSquare(
	var/list/map,
	var/x,
	var/y,
	var/size,
	var/thickness,
	var/tile
)
	if(size <= 0 || thickness <= 0)
		return

	DrawThickRectangle(
		map,
		x,
		y,
		size,
		size,
		thickness,
		tile
	)


// ============================================================
// THICK RECTANGLE
// ============================================================
//
// Draws a rectangular outline with the specified thickness.
//
// x/y represent the top-left corner.
//
// width/height represent the OUTER dimensions of the
// rectangle.
//
// thickness represents how many tiles thick the border is.
//
// The border is drawn inward from the outer dimensions.
//
// ============================================================

world/proc/DrawThickRectangle(
	var/list/map,
	var/x,
	var/y,
	var/width,
	var/height,
	var/thickness,
	var/tile
)
	if(width <= 0 || height <= 0 || thickness <= 0)
		return

	// A border cannot be thicker than half of the
	// rectangle's smallest dimension.
	thickness = min(
		thickness,
		round(min(width, height) / 2)
	)

	// --------------------------------------------------------
	// Top border
	// --------------------------------------------------------

	for(var/i = 0, i < thickness, i++)
		DrawHorizontalLine(
			map,
			x + i,
			y + i,
			width - (i * 2),
			tile
		)

	// --------------------------------------------------------
	// Bottom border
	// --------------------------------------------------------

	for(var/i = 0, i < thickness, i++)
		DrawHorizontalLine(
			map,
			x + i,
			y + height - 1 - i,
			width - (i * 2),
			tile
		)

	// --------------------------------------------------------
	// Left border
	// --------------------------------------------------------

	for(var/i = 0, i < thickness, i++)
		DrawVerticalLine(
			map,
			x + i,
			y + thickness,
			height - (thickness * 2),
			tile
		)

	// --------------------------------------------------------
	// Right border
	// --------------------------------------------------------

	for(var/i = 0, i < thickness, i++)
		DrawVerticalLine(
			map,
			x + width - 1 - i,
			y + thickness,
			height - (thickness * 2),
			tile
		)

// ============================================================
// MAP DRAWING - PASS 3A
// ============================================================
//
// Rounded rectangles and squares.
//
// These functions create rounded corners by combining:
//
//     - Horizontal / vertical lines
//     - Filled rectangles
//     - Filled circles
//
// The radius represents the size of the rounded corners.
//
// x/y represent the top-left corner.
// width/height represent the OUTER dimensions.
//
// Added in this pass:
//
//     DrawRoundedRectangle()
//     DrawFilledRoundedRectangle()
//
//     DrawRoundedSquare()
//     DrawFilledRoundedSquare()
//
// ============================================================


// ============================================================
// ROUNDED RECTANGLE
// ============================================================
//
// Draws the outline of a rectangle with rounded corners.
//
// Example:
//
//     DrawRoundedRectangle(
//         map,
//         20, 20,
//         60, 40,
//         5,
//         TILE_ROCKY
//     )
//
// Radius is automatically limited so that the rounded corners
// cannot overlap each other.
//
// ============================================================
world/proc/DrawRoundedRectangle(
	var/list/map,
	var/x,
	var/y,
	var/width,
	var/height,
	var/radius,
	var/tile
)
	if(width <= 0 || height <= 0 || radius < 0)
		return

	// Don't allow the radius to consume more than half
	// of the rectangle's smallest dimension.
	radius = min(radius, round(min(width, height) / 2))

	// Radius of zero is just a normal rectangle.
	if(radius <= 0)
		DrawRectangle(map, x, y, width, height, tile)
		return

	// ------------------------------------------------------------
	// Straight portions
	// ------------------------------------------------------------

	DrawHorizontalLine(
		map,
		x + radius,
		y,
		width - (radius * 2),
		tile
	)

	DrawHorizontalLine(
		map,
		x + radius,
		y + height - 1,
		width - (radius * 2),
		tile
	)

	DrawVerticalLine(
		map,
		x,
		y + radius,
		height - (radius * 2),
		tile
	)

	DrawVerticalLine(
		map,
		x + width - 1,
		y + radius,
		height - (radius * 2),
		tile
	)

	// ------------------------------------------------------------
	// Rounded corners
	//
	// Each corner is only a quarter of a circle.
	// ------------------------------------------------------------

	// Bottom-left
	DrawArc(
		map,
		x + radius,
		y + radius,
		radius,
		180,
		270,
		tile
	)

	// Bottom-right
	DrawArc(
		map,
		x + width - 1 - radius,
		y + radius,
		radius,
		270,
		360,
		tile
	)

	// Top-right
	DrawArc(
		map,
		x + width - 1 - radius,
		y + height - 1 - radius,
		radius,
		0,
		90,
		tile
	)

	// Top-left
	DrawArc(
		map,
		x + radius,
		y + height - 1 - radius,
		radius,
		90,
		180,
		tile
	)


// ============================================================
// FILLED ROUNDED RECTANGLE
// ============================================================
//
// Draws a filled rectangle with rounded corners.
//
// The interior is constructed from a central rectangle,
// horizontal sections, and four filled circles.
//
// ============================================================

world/proc/DrawFilledRoundedRectangle(
	var/list/map,
	var/x,
	var/y,
	var/width,
	var/height,
	var/radius,
	var/tile
)
	if(width <= 0 || height <= 0 || radius < 0)
		return

	radius = min(
		radius,
		round(min(width, height) / 2)
	)

	// --------------------------------------------------------
	// No radius
	// --------------------------------------------------------

	if(radius <= 0)
		DrawFilledRectangle(
			map,
			x,
			y,
			width,
			height,
			tile
		)
		return

	// --------------------------------------------------------
	// Central body
	// --------------------------------------------------------

	DrawFilledRectangle(
		map,
		x + radius,
		y,
		width - (radius * 2),
		height,
		tile
	)

	// --------------------------------------------------------
	// Middle section
	// --------------------------------------------------------

	DrawFilledRectangle(
		map,
		x,
		y + radius,
		width,
		height - (radius * 2),
		tile
	)

	// --------------------------------------------------------
	// Rounded corners
	// --------------------------------------------------------

	DrawFilledCircle(
		map,
		x + radius,
		y + radius,
		radius,
		tile
	)

	DrawFilledCircle(
		map,
		x + width - 1 - radius,
		y + radius,
		radius,
		tile
	)

	DrawFilledCircle(
		map,
		x + radius,
		y + height - 1 - radius,
		radius,
		tile
	)

	DrawFilledCircle(
		map,
		x + width - 1 - radius,
		y + height - 1 - radius,
		radius,
		tile
	)


// ============================================================
// ROUNDED SQUARE
// ============================================================
//
// Convenience wrapper around DrawRoundedRectangle().
//
// x/y represent the top-left corner.
//
// ============================================================

world/proc/DrawRoundedSquare(
	var/list/map,
	var/x,
	var/y,
	var/size,
	var/radius,
	var/tile
)
	if(size <= 0)
		return

	DrawRoundedRectangle(
		map,
		x,
		y,
		size,
		size,
		radius,
		tile
	)


// ============================================================
// FILLED ROUNDED SQUARE
// ============================================================
//
// Convenience wrapper around DrawFilledRoundedRectangle().
//
// x/y represent the top-left corner.
//
// ============================================================

world/proc/DrawFilledRoundedSquare(
	var/list/map,
	var/x,
	var/y,
	var/size,
	var/radius,
	var/tile
)
	if(size <= 0)
		return

	DrawFilledRoundedRectangle(
		map,
		x,
		y,
		size,
		size,
		radius,
		tile
	)

// ============================================================
// MAP DRAWING - PASS 3B
// ============================================================
//
// Rounded triangles and hexagons.
//
// These functions create rounded polygon shapes by replacing
// sharp corners with small circular arcs.
//
// The radius represents the approximate amount of rounding
// applied to each corner.
//
// Added in this pass:
//
//     DrawRoundedTriangle()
//     DrawFilledRoundedTriangle()
//
//     DrawRoundedHexagon()
//     DrawFilledRoundedHexagon()
//
// ============================================================


// ============================================================
// LOBED TRIANGLE
// ============================================================
//
// Draws a triangle with lobed corners.
//
// x/y represent the center of the triangle's base.
// base represents the width of the base.
// height represents the height.
//
// radius controls how far the corners are rounded.
//
// ============================================================

world/proc/DrawLobedTriangle(
	var/list/map,
	var/cx,
	var/y,
	var/base,
	var/height,
	var/radius,
	var/tile
)
	if(base <= 0 || height <= 0 || radius < 0)
		return

	if(radius <= 0)
		DrawTriangle(
			map,
			cx,
			y,
			base,
			height,
			tile
		)
		return

	// Keep the radius small enough that the three rounded
	// corners cannot consume the entire triangle.
	radius = min(
		radius,
		round(min(base / 2, height / 3))
	)

	if(radius <= 0)
		DrawTriangle(
			map,
			cx,
			y,
			base,
			height,
			tile
		)
		return

	// --------------------------------------------------------
	// Calculate the triangle's three corners.
	// --------------------------------------------------------

	var/left_x = round(cx - (base / 2))
	var/right_x = round(cx + (base / 2))
	var/bottom_y = y
	var/top_x = cx
	var/top_y = y + height - 1

	// --------------------------------------------------------
	// Calculate points slightly inward from each corner.
	//
	// These form the endpoints of the rounded sections.
	// --------------------------------------------------------

	var/left_bottom_x = left_x + radius
	var/left_bottom_y = bottom_y

	var/right_bottom_x = right_x - radius
	var/right_bottom_y = bottom_y

	var/top_left_x = top_x - radius
	var/top_left_y = top_y - radius

	var/top_right_x = top_x + radius
	var/top_right_y = top_y - radius

	// --------------------------------------------------------
	// Bottom edge
	// --------------------------------------------------------

	DrawLine(
		map,
		left_bottom_x,
		left_bottom_y,
		right_bottom_x,
		right_bottom_y,
		tile
	)

	// --------------------------------------------------------
	// Left edge
	// --------------------------------------------------------

	DrawLine(
		map,
		left_bottom_x,
		left_bottom_y,
		top_left_x,
		top_left_y,
		tile
	)

	// --------------------------------------------------------
	// Right edge
	// --------------------------------------------------------

	DrawLine(
		map,
		right_bottom_x,
		right_bottom_y,
		top_right_x,
		top_right_y,
		tile
	)

	// --------------------------------------------------------
	// Rounded corners
	//
	// Small filled circles are used here so the rasterized
	// result remains continuous on the tile grid.
	// --------------------------------------------------------

	DrawCircle(
		map,
		left_x + radius,
		bottom_y + radius,
		radius,
		tile
	)

	DrawCircle(
		map,
		right_x - radius,
		bottom_y + radius,
		radius,
		tile
	)

	DrawCircle(
		map,
		top_x,
		top_y - radius,
		radius,
		tile
	)


// ============================================================
// FILLED LOBED TRIANGLE
// ============================================================
//
// Draws a filled triangle with lobed corners.
//
// The shape is constructed by drawing the rounded outline and
// then filling the interior using horizontal scan lines.
//
// ============================================================

world/proc/DrawFilledLobedTriangle(
	var/list/map,
	var/cx,
	var/y,
	var/base,
	var/height,
	var/radius,
	var/tile
)
	if(base <= 0 || height <= 0 || radius < 0)
		return

	if(radius <= 0)
		DrawFilledTriangle(
			map,
			cx,
			y,
			base,
			height,
			tile
		)
		return

	radius = min(
		radius,
		round(min(base / 2, height / 3))
	)

	if(radius <= 0)
		DrawFilledTriangle(
			map,
			cx,
			y,
			base,
			height,
			tile
		)
		return

	// --------------------------------------------------------
	// Fill the main triangle.
	//
	// The rounded corner circles are drawn afterward to extend
	// the shape smoothly into the rounded areas.
	// --------------------------------------------------------

	DrawFilledTriangle(
		map,
		cx,
		y,
		base,
		height,
		tile
	)

	// --------------------------------------------------------
	// Rounded corners
	// --------------------------------------------------------

	DrawFilledCircle(
		map,
		round(cx - (base / 2)) + radius,
		y + radius,
		radius,
		tile
	)

	DrawFilledCircle(
		map,
		round(cx + (base / 2)) - radius,
		y + radius,
		radius,
		tile
	)

	DrawFilledCircle(
		map,
		cx,
		y + height - 1 - radius,
		radius,
		tile
	)


// ============================================================
// LOBED HEXAGON
// ============================================================
//
// Draws a hexagon with encircled corners.
//
// x/y represent the center.
// radius represents the overall size of the hexagon.
// corner_radius controls the amount of rounding.
//
// ============================================================

world/proc/DrawLobedHexagon(
	var/list/map,
	var/cx,
	var/cy,
	var/radius,
	var/corner_radius,
	var/tile
)
	if(radius <= 0 || corner_radius < 0)
		return

	if(corner_radius <= 0)
		DrawHexagon(
			map,
			cx,
			cy,
			radius,
			tile
		)
		return

	// Prevent the corner radius from becoming larger than
	// the hexagon itself.
	corner_radius = min(
		corner_radius,
		round(radius / 3)
	)

	if(corner_radius <= 0)
		DrawHexagon(
			map,
			cx,
			cy,
			radius,
			tile
		)
		return

	// --------------------------------------------------------
	// Calculate the six hexagon vertices.
	// --------------------------------------------------------

	var/list/points = list()

	points += list(list(
		cx,
		cy + radius
	))

	points += list(list(
		round(cx + (radius * 0.866)),
		round(cy + (radius * 0.5))
	))

	points += list(list(
		round(cx + (radius * 0.866)),
		round(cy - (radius * 0.5))
	))

	points += list(list(
		cx,
		cy - radius
	))

	points += list(list(
		round(cx - (radius * 0.866)),
		round(cy - (radius * 0.5))
	))

	points += list(list(
		round(cx - (radius * 0.866)),
		round(cy + (radius * 0.5))
	))

	// --------------------------------------------------------
	// Draw each shortened edge.
	// --------------------------------------------------------

	for(var/i = 1, i <= 6, i++)
		var/next = i + 1

		if(next > 6)
			next = 1

		var/list/p1 = points[i]
		var/list/p2 = points[next]

		var/x1 = p1[1]
		var/y1 = p1[2]
		var/x2 = p2[1]
		var/y2 = p2[2]

		var/dx = x2 - x1
		var/dy = y2 - y1
		var/length = sqrt((dx * dx) + (dy * dy))

		if(length <= 0)
			continue

		var/offset_x = (dx / length) * corner_radius
		var/offset_y = (dy / length) * corner_radius

		DrawLine(
			map,
			round(x1 + offset_x),
			round(y1 + offset_y),
			round(x2 - offset_x),
			round(y2 - offset_y),
			tile
		)

	// --------------------------------------------------------
	// Draw rounded corners.
	//
	// The vertex itself is used as the center of the small
	// rasterized corner arc.
	// --------------------------------------------------------

	for(var/i = 1, i <= 6, i++)
		var/list/p = points[i]

		DrawCircle(
			map,
			p[1],
			p[2],
			corner_radius,
			tile
		)


// ============================================================
// FILLED LOBED HEXAGON
// ============================================================
//
// Draws a filled hexagon with encircled corners.
//
// The underlying filled hexagon provides the main body while
// filled circles soften the six corners.
//
// ============================================================

world/proc/DrawFilledLobedHexagon(
	var/list/map,
	var/cx,
	var/cy,
	var/radius,
	var/corner_radius,
	var/tile
)
	if(radius <= 0 || corner_radius < 0)
		return

	if(corner_radius <= 0)
		DrawFilledHexagon(
			map,
			cx,
			cy,
			radius,
			tile
		)
		return

	corner_radius = min(
		corner_radius,
		round(radius / 3)
	)

	if(corner_radius <= 0)
		DrawFilledHexagon(
			map,
			cx,
			cy,
			radius,
			tile
		)
		return

	// --------------------------------------------------------
	// Main body
	// --------------------------------------------------------

	DrawFilledHexagon(
		map,
		cx,
		cy,
		radius,
		tile
	)

	// --------------------------------------------------------
	// Rounded corners
	// --------------------------------------------------------

	var/list/points = list()

	points += list(list(
		cx,
		cy + radius
	))

	points += list(list(
		round(cx + (radius * 0.866)),
		round(cy + (radius * 0.5))
	))

	points += list(list(
		round(cx + (radius * 0.866)),
		round(cy - (radius * 0.5))
	))

	points += list(list(
		cx,
		cy - radius
	))

	points += list(list(
		round(cx - (radius * 0.866)),
		round(cy - (radius * 0.5))
	))

	points += list(list(
		round(cx - (radius * 0.866)),
		round(cy + (radius * 0.5))
	))

	for(var/i = 1, i <= 6, i++)
		var/list/p = points[i]

		DrawFilledCircle(
			map,
			p[1],
			p[2],
			corner_radius,
			tile
		)


world/proc/DrawRoundedTriangle(
	var/list/map,
	var/cx,
	var/y,
	var/base,
	var/height,
	var/radius,
	var/tile
)
	if(base <= 0 || height <= 0 || radius < 0)
		return

	// A radius of zero is just a normal triangle.
	if(radius == 0)
		DrawTriangle(map, cx, y, base, height, tile)
		return

	// ------------------------------------------------------------
	// Define the three original triangle vertices.
	//
	//        TOP
	//         /\
	//        /  \
	//       /    \
	//      /______\
	//    LEFT     RIGHT
	// ------------------------------------------------------------

	var/left_x = round(cx - (base / 2))
	var/right_x = round(cx + (base / 2))
	var/bottom_y = y
	var/top_y = y + height - 1

	// ------------------------------------------------------------
	// Calculate the lengths of the three sides.
	// ------------------------------------------------------------

	var/side_left = sqrt( ((cx - left_x) * (cx - left_x)) + ((top_y - bottom_y) * (top_y - bottom_y)))

	var/side_right = side_left
	var/side_base = right_x - left_x

	// ------------------------------------------------------------
	// Work out the three interior angles.
	//
	// The top angle is between the two sloping sides.
	// The bottom angles are equal because this is isosceles.
	// ------------------------------------------------------------

	var/top_angle = 2 * arctan(
		(side_base / 2),
		(top_y - bottom_y)
	)

	// arctan() gives us the angle of half the triangle.
	// Convert that into the actual top interior angle.
	top_angle = 180 - (2 * top_angle)

	var/bottom_angle = (180 - top_angle) / 2

	// ------------------------------------------------------------
	// The distance from a vertex to each tangent point is:
	//
	//     d = radius / tan(angle / 2)
	//
	// This is the important part of the rounded-corner geometry.
	// ------------------------------------------------------------

	var/top_distance = radius / tan(top_angle / 2)
	var/bottom_distance = radius / tan(bottom_angle / 2)

	// Don't allow the rounding to consume the entire side.
	var/max_distance = min(
		side_left,
		side_right,
		side_base
	) / 2

	top_distance = min(top_distance, max_distance)
	bottom_distance = min(bottom_distance, max_distance)

	// ------------------------------------------------------------
	// Find the tangent points.
	//
	// Each point lies along one of the triangle's sides,
	// moving inward from its vertex.
	// ------------------------------------------------------------

	// Bottom-left corner:
	var/bl_x = left_x + (bottom_distance / side_base) * (right_x - left_x)
	var/bl_y = bottom_y

	// Bottom-right corner:
	var/br_x = right_x - (bottom_distance / side_base) * (right_x - left_x)
	var/br_y = bottom_y

	// Top-left side tangent:
	var/tl_x = left_x + (top_distance / side_left) * (cx - left_x)
	var/tl_y = bottom_y + (top_distance / side_left) * (top_y - bottom_y)

	// Top-right side tangent:
	var/tr_x = right_x - (top_distance / side_right) * (right_x - cx)
	var/tr_y = bottom_y + (top_distance / side_right) * (top_y - bottom_y)

	// ------------------------------------------------------------
	// Round the coordinates because we're drawing onto tiles.
	// ------------------------------------------------------------

	bl_x = round(bl_x)
	bl_y = round(bl_y)

	br_x = round(br_x)
	br_y = round(br_y)

	tl_x = round(tl_x)
	tl_y = round(tl_y)

	tr_x = round(tr_x)
	tr_y = round(tr_y)

	// ------------------------------------------------------------
	// Draw the three straight portions of the triangle.
	// ------------------------------------------------------------

	DrawLine(map, tl_x, tl_y, tr_x, tr_y, tile)
	DrawLine(map, tr_x, tr_y, br_x, br_y, tile)
	DrawLine(map, br_x, br_y, bl_x, bl_y, tile)

	// ------------------------------------------------------------
	// For the arcs, we need the actual centers of the circles.
	//
	// The center of a rounded corner lies on the angle bisector.
	// ------------------------------------------------------------

	// Bottom-left arc center.
	var/bl_center_x = left_x + bottom_distance
	var/bl_center_y = bottom_y + radius

	// Bottom-right arc center.
	var/br_center_x = right_x - bottom_distance
	var/br_center_y = bottom_y + radius

	// Top arc center.
	var/top_center_x = cx
	var/top_center_y = top_y - radius

	// ------------------------------------------------------------
	// Draw the bottom-left corner.
	//
	// From the left-side tangent to the bottom tangent.
	// ------------------------------------------------------------

	DrawArc(
		map,
		round(bl_center_x),
		round(bl_center_y),
		radius,
		270,
		360,
		tile
	)

	// ------------------------------------------------------------
	// Draw the bottom-right corner.
	// ------------------------------------------------------------

	DrawArc(
		map,
		round(br_center_x),
		round(br_center_y),
		radius,
		180,
		270,
		tile
	)

	// ------------------------------------------------------------
	// Draw the top corner.
	// ------------------------------------------------------------

	DrawArc(
		map,
		round(top_center_x),
		round(top_center_y),
		radius,
		0,
		180,
		tile
	)