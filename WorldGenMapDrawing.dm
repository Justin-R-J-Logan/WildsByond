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
// DRAW THICK LINE
// ============================================================
//
// Draws a thick line between two coordinates.
//
// The centerline uses the same Bresenham-style logic as
// DrawLine().
//
// At each point along the centerline, a filled circle is
// stamped onto the map. This creates:
//
//     - continuous thickness
//     - rounded ends
//     - smooth joins
//     - no gaps between parallel rasterized lines
//
// thickness represents the approximate width of the line.
//
// Odd thickness values such as:
//
//     1, 3, 5, 7...
//
// will be the most symmetrical on an integer tile grid.
//
// Even thickness values cannot be perfectly centered on a
// single tile, so they will rasterize approximately.
//
// ============================================================

world/proc/DrawThickLine(
	var/list/map,
	var/x1,
	var/y1,
	var/x2,
	var/y2,
	var/thickness,
	var/tile
)
	if(thickness <= 0)
		return

	// A thickness of 1 is just a normal line.
	if(thickness == 1)
		DrawLine(
			map,
			x1,
			y1,
			x2,
			y2,
			tile
		)
		return

	// --------------------------------------------------------
	// Convert thickness into the radius of the circular brush.
	//
	// Examples:
	//
	//     thickness 3 -> radius 1
	//     thickness 5 -> radius 2
	//     thickness 7 -> radius 3
	//
	// For even thicknesses this rounds to the nearest usable
	// tile-grid brush size.
	// --------------------------------------------------------

	var/brush_radius = round(thickness / 2)

	if(brush_radius < 1)
		brush_radius = 1


	// --------------------------------------------------------
	// Bresenham centerline.
	// --------------------------------------------------------

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

		// Stamp a filled circular brush at every centerline
		// position.
		DrawFilledCircle(
			map,
			x1,
			y1,
			brush_radius,
			tile
		)

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
// DRAW POLYLINE
// ============================================================
//
// Draws a continuous line through a list of points.
//
// points should be supplied in this format:
//
//     list(
//         list(x1, y1),
//         list(x2, y2),
//         list(x3, y3)
//     )
//
// Each point is connected to the next using DrawLine().
//
// This is useful for things such as:
//
//     - rivers
//     - roads
//     - trails
//     - irregular boundaries
//     - generated paths
//
// A minimum of two points is required.
//
// ============================================================
world/proc/DrawPolyline(
	var/list/map,
	var/list/points,
	var/tile
)
	if(!points || points.len < 2)
		return

	for(var/i = 1, i < points.len, i++)
		var/list/start = points[i]
		var/list/end = points[i + 1]

		if(!start || !end)
			continue

		if(start.len < 2 || end.len < 2)
			continue

		DrawLine(
			map,
			start[1],
			start[2],
			end[1],
			end[2],
			tile
		)

// ============================================================
// DRAW THICK POLYLINE
// ============================================================
//
// Draws a continuous thick line through a list of points.
//
// points should be supplied in this format:
//
//     list(
//         list(x1, y1),
//         list(x2, y2),
//         list(x3, y3)
//     )
//
// Each point is connected to the next using DrawThickLine().
//
// This is especially useful for:
//
//     - rivers
//     - roads
//     - trails
//     - ravines
//     - wide generated paths
//
// thickness controls the width of the line.
//
// A minimum of two points is required.
//
// ============================================================

world/proc/DrawThickPolyline(
	var/list/map,
	var/list/points,
	var/thickness,
	var/tile
)
	if(!points || points.len < 2)
		return

	if(thickness <= 0)
		return

	for(var/i = 1, i < points.len, i++)

		var/list/start = points[i]
		var/list/end = points[i + 1]

		if(!start || !end)
			continue

		if(start.len < 2 || end.len < 2)
			continue

		DrawThickLine(
			map,
			start[1],
			start[2],
			end[1],
			end[2],
			thickness,
			tile
		)

// ============================================================
// DRAW CURVE
// ============================================================
//
// Draws a quadratic Bezier curve between two points.
//
// x1 / y1:
//     Starting point.
//
// control_x / control_y:
//     Control point that determines the direction and amount
//     of curvature.
//
// x2 / y2:
//     Ending point.
//
// The curve is sampled into a list of points, then passed to
// DrawPolyline().
//
// Sampling resolution is based on the approximate length of
// the two control-line segments. This gives longer curves
// more samples automatically.
//
// ============================================================

world/proc/DrawCurve(
	var/list/map,
	var/x1,
	var/y1,
	var/control_x,
	var/control_y,
	var/x2,
	var/y2,
	var/tile
)
	// Estimate curve length using the two control lines.

	var/dx1 = control_x - x1
	var/dy1 = control_y - y1

	var/dx2 = x2 - control_x
	var/dy2 = y2 - control_y

	var/length1 = sqrt((dx1 * dx1) +(dy1 * dy1))

	var/length2 = sqrt( (dx2 * dx2) + (dy2 * dy2) )

	var/estimated_length = length1 + length2

	// Sample at roughly twice per tile of estimated length.
	// DrawPolyline() handles connecting the resulting points.

	var/segments = max(
		4,
		round(estimated_length * 2)
	)

	var/list/points = list()

	var/last_x = null
	var/last_y = null

	for(var/i = 0, i <= segments, i++)

		var/t = i / segments
		var/inverse_t = 1 - t

		// Quadratic Bezier formula:
		//
		// P(t) =
		// (1-t)^2 P0 +
		// 2(1-t)t P1 +
		// t^2 P2

		var/draw_x = round( (inverse_t * inverse_t * x1) + (2 * inverse_t * t * control_x) + (t * t * x2))

		var/draw_y = round( (inverse_t * inverse_t * y1) + (2 * inverse_t * t * control_y) + (t * t * y2))

		// Don't add duplicate rasterized points.

		if(draw_x == last_x && draw_y == last_y)
			continue

		points += list(
			list(draw_x, draw_y)
		)

		last_x = draw_x
		last_y = draw_y

	if(points.len >= 2)
		DrawPolyline(
			map,
			points,
			tile
		)

	else if(points.len == 1)
		DrawPixel(
			map,
			points[1][1],
			points[1][2],
			tile
		)

// ============================================================
// DRAW THICK CURVE
// ============================================================
//
// Draws a thick quadratic Bezier curve between two points.
//
// Uses the same curve generation as DrawCurve(), but sends
// the generated points to DrawThickPolyline().
//
// thickness:
//     Thickness of the resulting curve in tiles.
//
// ============================================================

world/proc/DrawThickCurve(
	var/list/map,
	var/x1,
	var/y1,
	var/control_x,
	var/control_y,
	var/x2,
	var/y2,
	var/thickness,
	var/tile
)
	if(thickness <= 0)
		return

	// A thickness of 1 can use the normal curve directly.

	if(thickness == 1)
		DrawCurve(
			map,
			x1,
			y1,
			control_x,
			control_y,
			x2,
			y2,
			tile
		)
		return

	var/dx1 = control_x - x1
	var/dy1 = control_y - y1

	var/dx2 = x2 - control_x
	var/dy2 = y2 - control_y

	var/length1 = sqrt( (dx1 * dx1) + (dy1 * dy1))

	var/length2 = sqrt( (dx2 * dx2) + (dy2 * dy2))

	var/estimated_length = length1 + length2

	var/segments = max(
		4,
		round(estimated_length * 2)
	)

	var/list/points = list()

	var/last_x = null
	var/last_y = null

	for(var/i = 0, i <= segments, i++)

		var/t = i / segments
		var/inverse_t = 1 - t

		var/draw_x = round((inverse_t * inverse_t * x1) + (2 * inverse_t * t * control_x) + (t * t * x2))

		var/draw_y = round( (inverse_t * inverse_t * y1) + (2 * inverse_t * t * control_y) + (t * t * y2))

		if(draw_x == last_x && draw_y == last_y)
			continue

		points += list(
			list(draw_x, draw_y)
		)

		last_x = draw_x
		last_y = draw_y

	if(points.len >= 2)
		DrawThickPolyline(
			map,
			points,
			thickness,
			tile
		)

	else if(points.len == 1)
		DrawPixel(
			map,
			points[1][1],
			points[1][2],
			tile
		)
// ============================================================
// DRAW SINE
// ============================================================
//
// Draws a sine-wave path between two arbitrary points.
//
// x1 / y1:
//     Starting point.
//
// x2 / y2:
//     Ending point.
//
// amplitude:
//     Maximum distance, in tiles, that the wave moves away
//     from the straight line between the two endpoints.
//
// waves:
//     Number of complete sine waves between the endpoints.
//     Whole numbers are recommended.
//
// The sine wave is calculated along the straight line between
// the two endpoints and displaced perpendicular to that line.
//
// The resulting points are passed to DrawPolyline().
//
// ============================================================

world/proc/DrawSine(
	var/list/map,
	var/x1,
	var/y1,
	var/x2,
	var/y2,
	var/amplitude,
	var/waves,
	var/tile
)
	var/dx = x2 - x1
	var/dy = y2 - y1

	var/distance = sqrt( (dx * dx) + (dy * dy) )

	// Both endpoints are the same.
	if(distance <= 0)
		DrawPixel(
			map,
			x1,
			y1,
			tile
		)
		return

	// No amplitude means the sine is simply a straight line.
	if(amplitude == 0 || waves <= 0)
		DrawLine(
			map,
			x1,
			y1,
			x2,
			y2,
			tile
		)
		return


	// --------------------------------------------------------
	// Calculate the perpendicular direction.
	//
	// Normalized line direction:
	//
	//     dx / distance
	//     dy / distance
	//
	// Rotating that direction 90 degrees gives:
	//
	//     -dy / distance
	//      dx / distance
	//
	// This is the direction in which the sine wave oscillates.
	// --------------------------------------------------------

	var/perpendicular_x = -dy / distance
	var/perpendicular_y = dx / distance


	// --------------------------------------------------------
	// Estimate the amount of sampling needed.
	//
	// Extra samples are added based on amplitude and wave
	// count so tightly curved waves remain reasonably smooth.
	// --------------------------------------------------------

	var/estimated_length = \
		distance + \
		(abs(amplitude) * waves * 4)

	var/segments = max(
		4,
		round(estimated_length * 2)
	)

	var/list/points = list()

	var/last_x = null
	var/last_y = null

	for(var/i = 0, i <= segments, i++)

		var/t = i / segments

		// Position along the straight center line.

		var/base_x = x1 + (dx * t)
		var/base_y = y1 + (dy * t)

		// BYOND trigonometric functions use degrees.
		//
		// 360 degrees = one complete sine wave.

		var/angle = 360 * waves * t

		var/offset = sin(angle) * amplitude

		var/draw_x = round( base_x + (perpendicular_x * offset))

		var/draw_y = round( base_y + (perpendicular_y * offset))

		// Ensure the exact endpoints are retained.
		if(i == 0)
			draw_x = x1
			draw_y = y1

		else if(i == segments)
			draw_x = x2
			draw_y = y2

		// Ignore duplicate points created by rasterization.

		if(draw_x == last_x && draw_y == last_y)
			continue

		points += list(
			list(draw_x, draw_y)
		)

		last_x = draw_x
		last_y = draw_y


	if(points.len >= 2)
		DrawPolyline(
			map,
			points,
			tile
		)

	else if(points.len == 1)
		DrawPixel(
			map,
			points[1][1],
			points[1][2],
			tile
		)
// ============================================================
// DRAW THICK SINE
// ============================================================
//
// Draws a thick sine-wave path between two arbitrary points.
//
// Uses the same geometry as DrawSine(), but passes the
// generated points to DrawThickPolyline().
//
// thickness:
//     Thickness of the resulting sine path in tiles.
//
// ============================================================

world/proc/DrawThickSine(
	var/list/map,
	var/x1,
	var/y1,
	var/x2,
	var/y2,
	var/amplitude,
	var/waves,
	var/thickness,
	var/tile
)
	if(thickness <= 0)
		return

	if(thickness == 1)
		DrawSine(
			map,
			x1,
			y1,
			x2,
			y2,
			amplitude,
			waves,
			tile
		)
		return


	var/dx = x2 - x1
	var/dy = y2 - y1

	var/distance = sqrt((dx * dx) + (dy * dy))

	if(distance <= 0)
		DrawFilledCircle(
			map,
			x1,
			y1,
			round(thickness / 2),
			tile
		)
		return

	if(amplitude == 0 || waves <= 0)
		DrawThickLine(
			map,
			x1,
			y1,
			x2,
			y2,
			thickness,
			tile
		)
		return


	var/perpendicular_x = -dy / distance
	var/perpendicular_y = dx / distance

	var/estimated_length = \
		distance + \
		(abs(amplitude) * waves * 4)

	var/segments = max(
		4,
		round(estimated_length * 2)
	)

	var/list/points = list()

	var/last_x = null
	var/last_y = null

	for(var/i = 0, i <= segments, i++)

		var/t = i / segments

		var/base_x = x1 + (dx * t)
		var/base_y = y1 + (dy * t)

		var/angle = 360 * waves * t
		var/offset = sin(angle) * amplitude

		var/draw_x = round(base_x + (perpendicular_x * offset))

		var/draw_y = round( base_y + (perpendicular_y * offset))

		if(i == 0)
			draw_x = x1
			draw_y = y1

		else if(i == segments)
			draw_x = x2
			draw_y = y2

		if(draw_x == last_x && draw_y == last_y)
			continue

		points += list(
			list(draw_x, draw_y)
		)

		last_x = draw_x
		last_y = draw_y


	if(points.len >= 2)
		DrawThickPolyline(
			map,
			points,
			thickness,
			tile
		)

	else if(points.len == 1)
		DrawFilledCircle(
			map,
			points[1][1],
			points[1][2],
			round(thickness / 2),
			tile
		)
// ============================================================
// DRAW POLYGON
// ============================================================
//
// Draws a closed polygon through a list of points.
//
// points should be supplied in this format:
//
//     list(
//         list(x1, y1),
//         list(x2, y2),
//         list(x3, y3)
//     )
//
// Each point is connected to the next using DrawLine().
//
// After the final point is drawn, it is connected back to
// the first point, closing the shape.
//
// This allows arbitrary polygon shapes such as:
//
//     - triangles
//     - quadrilaterals
//     - pentagons
//     - irregular terrain regions
//     - custom boundaries
//
// A minimum of three points is required.
//
// ============================================================

world/proc/DrawPolygon(
	var/list/map,
	var/list/points,
	var/tile
)
	if(!points || points.len < 3)
		return

	// Draw each point to the next point.
	for(var/i = 1, i < points.len, i++)

		var/list/start = points[i]
		var/list/end = points[i + 1]

		if(!start || !end)
			continue

		if(start.len < 2 || end.len < 2)
			continue

		DrawLine(
			map,
			start[1],
			start[2],
			end[1],
			end[2],
			tile
		)

	// --------------------------------------------------------
	// Close the polygon by connecting the last point back
	// to the first point.
	// --------------------------------------------------------

	var/list/last = points[points.len]
	var/list/first = points[1]

	if(
		last && first && last.len >= 2 && first.len >= 2
	)
		DrawLine(
			map,
			last[1],
			last[2],
			first[1],
			first[2],
			tile
		)
// ============================================================
// DRAW THICK POLYGON
// ============================================================
//
// Draws a closed polygon using thick line segments.
//
// points:
//     A list of coordinate pairs:
//
//     list(
//         list(x1, y1),
//         list(x2, y2),
//         list(x3, y3)
//     )
//
// Each adjacent pair of points is connected using
// DrawThickLine(), and the final point is connected back to
// the first point to close the polygon.
//
// A minimum of three points is required.
//
// thickness:
//     Thickness of the polygon outline in tiles.
//
// ============================================================

world/proc/DrawThickPolygon(
	var/list/map,
	var/list/points,
	var/thickness,
	var/tile
)
	if(!points || points.len < 3)
		return

	if(thickness <= 0)
		return

	// Draw each consecutive edge.

	for(var/i = 1, i < points.len, i++)

		var/list/start = points[i]
		var/list/end = points[i + 1]

		if(!start || start.len < 2)
			continue

		if(!end || end.len < 2)
			continue

		DrawThickLine(
			map,
			start[1],
			start[2],
			end[1],
			end[2],
			thickness,
			tile
		)

	// Close the polygon by connecting the final point
	// back to the first point.

	var/list/last = points[points.len]
	var/list/first = points[1]

	if(last && last.len >= 2 && first && first.len >= 2)
		DrawThickLine(
			map,
			last[1],
			last[2],
			first[1],
			first[2],
			thickness,
			tile
		)
// ============================================================
// DRAW FILLED POLYGON
// ============================================================
//
// Draws a filled polygon through a list of points.
//
// points should be supplied in this format:
//
//     list(
//         list(x1, y1),
//         list(x2, y2),
//         list(x3, y3)
//     )
//
// The polygon is filled using a scanline algorithm.
//
// This supports both convex and concave polygons.
//
// A minimum of three points is required.
//
// ============================================================

world/proc/DrawFilledPolygon(
	var/list/map,
	var/list/points,
	var/tile
)
	if(!points || points.len < 3)
		return

	// --------------------------------------------------------
	// Find vertical bounds.
	// --------------------------------------------------------

	var/min_y = null
	var/max_y = null

	for(var/list/point in points)

		if(!point || point.len < 2)
			continue

		var/py = point[2]

		if(isnull(min_y) || py < min_y)
			min_y = py

		if(isnull(max_y) || py > max_y)
			max_y = py

	if(isnull(min_y) || isnull(max_y))
		return


	// --------------------------------------------------------
	// Process one horizontal scanline at a time.
	// --------------------------------------------------------

	for(var/draw_y = min_y, draw_y <= max_y, draw_y++)

		var/list/intersections = list()


		// ----------------------------------------------------
		// Check every polygon edge for intersection with
		// this scanline.
		// ----------------------------------------------------

		for(var/i = 1, i <= points.len, i++)

			var/next_i = i + 1

			if(next_i > points.len)
				next_i = 1

			var/list/p1 = points[i]
			var/list/p2 = points[next_i]

			if(!p1 || !p2 || p1.len < 2 || p2.len < 2 )
				continue


			var/x1 = p1[1]
			var/y1 = p1[2]

			var/x2 = p2[1]
			var/y2 = p2[2]


			// Horizontal edges don't need to contribute
			// scanline intersections.
			if(y1 == y2)
				continue


			// ------------------------------------------------
			// Use a half-open edge test:
			//
			//     minY <= scanY < maxY
			//
			// This prevents vertices shared by two edges from
			// being counted twice.
			// ------------------------------------------------

			var/edge_min_y = min(y1, y2)
			var/edge_max_y = max(y1, y2)

			if(draw_y < edge_min_y || draw_y >= edge_max_y )
				continue


			// ------------------------------------------------
			// Calculate where the edge crosses this row.
			// ------------------------------------------------

			var/progress = \
				(draw_y - y1) / \
				(y2 - y1)

			var/intersection_x = \
				x1 + \
				((x2 - x1) * progress)

			intersections += intersection_x


		// ----------------------------------------------------
		// Need at least two crossings to fill anything.
		// ----------------------------------------------------

		if(intersections.len < 2)
			continue


		// ----------------------------------------------------
		// Sort intersections from left to right.
		//
		// Simple insertion sort is fine here because polygons
		// will generally have very few vertices.
		// ----------------------------------------------------

		for(var/i = 2, i <= intersections.len, i++)

			var/value = intersections[i]
			var/j = i - 1

			while(j >= 1 && intersections[j] > value )

				intersections[j + 1] = intersections[j]
				j--

			intersections[j + 1] = value


		// ----------------------------------------------------
		// Fill between crossing pairs.
		//
		// Crossing pairs:
		//
		//     1 -> 2
		//     3 -> 4
		//     5 -> 6
		//
		// This correctly handles concave polygons.
		// ----------------------------------------------------

		for(var/i = 1, i < intersections.len, i += 2)

			var/start_x = round(intersections[i])
			var/end_x = round(intersections[i + 1])

			if(end_x < start_x)

				var/temp = start_x
				start_x = end_x
				end_x = temp

			DrawHorizontalLine(
				map,
				start_x,
				draw_y,
				(end_x - start_x) + 1,
				tile
			)


	// --------------------------------------------------------
	// Draw the outline last.
	//
	// This guarantees the boundary matches DrawPolygon()
	// exactly even where scanline rounding differs slightly.
	// --------------------------------------------------------

	DrawPolygon(
		map,
		points,
		tile
	)
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

	if(radius == 0)
		DrawPixel(map, cx, cy, tile)
		return

	var/x = radius
	var/y = 0
	var/decision = 1 - radius

	while(x >= y)

		// Fill the horizontal spans represented by the
		// eight symmetrical points of the midpoint circle.

		DrawHorizontalLine(
			map,
			cx - x,
			cy + y,
			(x * 2) + 1,
			tile
		)

		DrawHorizontalLine(
			map,
			cx - x,
			cy - y,
			(x * 2) + 1,
			tile
		)

		DrawHorizontalLine(
			map,
			cx - y,
			cy + x,
			(y * 2) + 1,
			tile
		)

		DrawHorizontalLine(
			map,
			cx - y,
			cy - x,
			(y * 2) + 1,
			tile
		)

		y++

		if(decision <= 0)
			decision += 2 * y + 1
		else
			x--
			decision += 2 * (y - x) + 1

// ============================================================
// DRAW ELLIPSE
// ============================================================
//
// Draws a 1-tile-thick ellipse outline centered on cx/cy.
//
// This proc uses DrawFilledEllipse() to generate a temporary
// mask, then extracts the edge tiles from that mask.
//
// A tile is considered part of the outline if it belongs to
// the filled ellipse and at least one of its four cardinal
// neighbours is outside the ellipse.
//
// This keeps the outline visually consistent with the filled
// version.
//
// Special cases:
//     rx = 0, ry = 0 -> single pixel
//     rx = 0         -> vertical line
//     ry = 0         -> horizontal line
//
// ============================================================

world/proc/DrawEllipse(
	var/list/map,
	var/cx,
	var/cy,
	var/radius_x,
	var/radius_y,
	var/tile
)
	if(radius_x < 0 || radius_y < 0)
		return

	// --------------------------------------------------------
	// Special cases.
	// --------------------------------------------------------

	if(radius_x == 0 && radius_y == 0)
		DrawPixel(map, cx, cy, tile)
		return

	if(radius_x == 0)
		DrawVerticalLine(
			map,
			cx,
			cy - radius_y,
			(radius_y * 2) + 1,
			tile
		)
		return

	if(radius_y == 0)
		DrawHorizontalLine(
			map,
			cx - radius_x,
			cy,
			(radius_x * 2) + 1,
			tile
		)
		return


	// --------------------------------------------------------
	// Build a temporary filled mask.
	// --------------------------------------------------------

	var/list/mask = list()
	var/MASK_TILE = 1

	DrawFilledEllipse(
		mask,
		cx,
		cy,
		radius_x,
		radius_y,
		MASK_TILE
	)


	// --------------------------------------------------------
	// Extract the outline from the filled mask.
	// --------------------------------------------------------

	var/min_x = cx - radius_x
	var/max_x = cx + radius_x
	var/min_y = cy - radius_y
	var/max_y = cy + radius_y

	for(var/draw_y = min_y, draw_y <= max_y, draw_y++)
		for(var/draw_x = min_x, draw_x <= max_x, draw_x++)

			if(MapGet(mask, draw_x, draw_y) != MASK_TILE)
				continue

			var/is_edge = FALSE

			if(MapGet(mask, draw_x + 1, draw_y) != MASK_TILE)
				is_edge = TRUE

			else if(MapGet(mask, draw_x - 1, draw_y) != MASK_TILE)
				is_edge = TRUE

			else if(MapGet(mask, draw_x, draw_y + 1) != MASK_TILE)
				is_edge = TRUE

			else if(MapGet(mask, draw_x, draw_y - 1) != MASK_TILE)
				is_edge = TRUE

			if(is_edge)
				DrawPixel(
					map,
					draw_x,
					draw_y,
					tile
				)

// ============================================================
// DRAW FILLED ELLIPSE
// ============================================================
//
// Draws a filled ellipse centered on cx/cy.
//
// The extreme top and bottom single-pixel tips are suppressed
// and blended into the adjacent rows to produce a smoother
// tile-art silhouette at low resolutions.
//
// ============================================================

world/proc/DrawFilledEllipse(
	var/list/map,
	var/cx,
	var/cy,
	var/radius_x,
	var/radius_y,
	var/tile
)
	if(radius_x < 0 || radius_y < 0)
		return

	if(radius_x == 0 && radius_y == 0)
		DrawPixel(map, cx, cy, tile)
		return

	if(radius_x == 0)
		DrawVerticalLine(
			map,
			cx,
			cy - radius_y,
			(radius_y * 2) + 1,
			tile
		)
		return

	if(radius_y == 0)
		DrawHorizontalLine(
			map,
			cx - radius_x,
			cy,
			(radius_x * 2) + 1,
			tile
		)
		return

	for(var/offset_y = -radius_y, offset_y <= radius_y, offset_y++)

		// Skip the mathematically correct 1-tile tips.
		// They are visually absorbed into the rows immediately
		// above/below them instead.
		if(abs(offset_y) == radius_y)
			continue

		var/y_ratio = offset_y / radius_y

		var/half_width = round(
			radius_x * sqrt(
				1 - (y_ratio * y_ratio)
			)
		)

		// Slightly widen the rows nearest the top and bottom
		// to compensate for removing the single-pixel tips.
		if(abs(offset_y) == radius_y - 1)
			half_width = max(
				half_width,
				1
			)

		DrawHorizontalLine(
			map,
			cx - half_width,
			cy + offset_y,
			(half_width * 2) + 1,
			tile
		)


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

	// --------------------------------------------------------
	// Calculate an exact base width.
	//
	// For an odd base:
	//
	//     base = 11
	//
	//     left  = cx - 5
	//     right = cx + 5
	//
	// giving exactly 11 tiles.
	//
	// For an even base there is no single exact center tile,
	// so the shape is centered between the two middle tiles.
	// --------------------------------------------------------

	var/left_x = cx - ((base - 1) / 2)
	var/right_x = left_x + base - 1

	left_x = round(left_x)
	right_x = left_x + base - 1

	var/top_y = y + height - 1

	// Keep the point centered relative to the actual base.
	var/top_x = round((left_x + right_x) / 2)

	// Base
	DrawHorizontalLine(
		map,
		left_x,
		y,
		base,
		tile
	)

	// Left side
	DrawLine(
		map,
		left_x,
		y,
		top_x,
		top_y,
		tile
	)

	// Right side
	DrawLine(
		map,
		right_x,
		y,
		top_x,
		top_y,
		tile
	)


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

	// Temporary map used only to capture the exact outline
	// produced by DrawTriangle().
	var/list/mask = list()

	// Draw the outline using an arbitrary marker value.
	var/MASK_TILE = 1

	DrawTriangle(
		mask,
		cx,
		y,
		base,
		height,
		MASK_TILE
	)

	// Work out the same horizontal bounds as DrawTriangle().
	var/left_x = cx - ((base - 1) / 2)
	left_x = round(left_x)

	var/right_x = left_x + base - 1

	// --------------------------------------------------------
	// Scan every row of the triangle.
	//
	// Find the first and last outline pixel on that row,
	// then fill everything between them.
	// --------------------------------------------------------

	for(var/draw_y = y, draw_y < y + height, draw_y++)

		var/start_x = null
		var/end_x = null

		for(var/draw_x = left_x, draw_x <= right_x, draw_x++)

			if(MapGet(mask, draw_x, draw_y) == MASK_TILE)

				if(isnull(start_x))
					start_x = draw_x

				end_x = draw_x

		// If this row contains part of the triangle outline,
		// fill from its left edge to its right edge.
		if(!isnull(start_x) && !isnull(end_x))

			DrawHorizontalLine(
				map,
				start_x,
				draw_y,
				(end_x - start_x) + 1,
				tile
			)

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

	// --------------------------------------------------------
	// Flat-top hexagon.
	//
	//              _______
	//            /         \
	//           /           \
	//           \           /
	//            \_________/
	//
	// Instead of drawing four independent diagonal lines,
	// generate one side and mirror it. This guarantees that
	// all four sloped sides use exactly the same rasterization.
	// --------------------------------------------------------

	var/half_width = round(radius / 2)
	var/half_height = round(radius * 0.866)

	if(half_height <= 0)
		DrawPixel(map, cx, cy, tile)
		return

	// --------------------------------------------------------
	// Flat top and bottom.
	// --------------------------------------------------------

	DrawHorizontalLine(
		map,
		cx - half_width,
		cy + half_height,
		(half_width * 2) + 1,
		tile
	)

	DrawHorizontalLine(
		map,
		cx - half_width,
		cy - half_height,
		(half_width * 2) + 1,
		tile
	)

	// --------------------------------------------------------
	// Sloped sides.
	//
	// At the middle of the hexagon:
	//
	//     x offset = radius
	//
	// At the top/bottom:
	//
	//     x offset = half_width
	//
	// Calculate that once for each row and mirror it to all
	// four sides.
	// --------------------------------------------------------

	var/previous_offset = radius

	for(var/dy = 0, dy <= half_height, dy++)

		var/progress = dy / half_height

		var/x_offset = round(
			radius - ((radius - half_width) * progress)
		)

		// ----------------------------------------------------
		// Draw the four mirrored edge positions.
		// ----------------------------------------------------

		DrawPixel(
			map,
			cx - x_offset,
			cy + dy,
			tile
		)

		DrawPixel(
			map,
			cx + x_offset,
			cy + dy,
			tile
		)

		DrawPixel(
			map,
			cx - x_offset,
			cy - dy,
			tile
		)

		DrawPixel(
			map,
			cx + x_offset,
			cy - dy,
			tile
		)

		// ----------------------------------------------------
		// If the staircase moved horizontally on this row,
		// connect the previous and current positions.
		//
		// This prevents little diagonal gaps and keeps the
		// outline continuous.
		// ----------------------------------------------------

		if(x_offset != previous_offset)

			var/min_offset = min(x_offset, previous_offset)
			var/max_offset = max(x_offset, previous_offset)
			var/step_width = (max_offset - min_offset) + 1

			// Upper-left
			DrawHorizontalLine(
				map,
				cx - max_offset,
				cy + dy,
				step_width,
				tile
			)

			// Upper-right
			DrawHorizontalLine(
				map,
				cx + min_offset,
				cy + dy,
				step_width,
				tile
			)

			// Lower-left
			DrawHorizontalLine(
				map,
				cx - max_offset,
				cy - dy,
				step_width,
				tile
			)

			// Lower-right
			DrawHorizontalLine(
				map,
				cx + min_offset,
				cy - dy,
				step_width,
				tile
			)

		previous_offset = x_offset



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

	// --------------------------------------------------------
	// Create a temporary mask so the filled hexagon matches
	// the exact outline produced by DrawHexagon().
	// --------------------------------------------------------

	var/list/mask = list()
	var/MASK_TILE = 1

	DrawHexagon(
		mask,
		cx,
		cy,
		radius,
		MASK_TILE
	)

	// --------------------------------------------------------
	// Determine the scan area.
	//
	// The current flat-top hexagon uses:
	//     half_width  = round(radius / 2)
	//     half_height = round(radius * 0.866)
	//
	// We only really need the full bounding box.
	// --------------------------------------------------------

	var/half_height = round(radius * 0.866)

	var/min_x = cx - radius
	var/max_x = cx + radius
	var/min_y = cy - half_height
	var/max_y = cy + half_height

	// --------------------------------------------------------
	// Scan each row.
	//
	// Find the first and last outline tile on that row, then
	// fill everything between them.
	// --------------------------------------------------------

	for(var/draw_y = min_y, draw_y <= max_y, draw_y++)
		var/start_x = null
		var/end_x = null

		for(var/draw_x = min_x, draw_x <= max_x, draw_x++)
			if(MapGet(mask, draw_x, draw_y) == MASK_TILE)
				if(isnull(start_x))
					start_x = draw_x

				end_x = draw_x

		if(!isnull(start_x) && !isnull(end_x))
			DrawHorizontalLine(
				map,
				start_x,
				draw_y,
				(end_x - start_x) + 1,
				tile
			)

// ============================================================
// DRAW N-GON
// ============================================================
//
// Draws a regular polygon with an arbitrary number of sides.
//
// cx/cy represent the center of the polygon.
//
// radius represents the distance from the center to each
// polygon vertex.
//
// sides represents the number of sides:
//
//     3 = triangle
//     4 = square
//     5 = pentagon
//     6 = hexagon
//     8 = octagon
//     etc.
//
// rotation rotates the polygon in degrees.
//
// Vertices are calculated at evenly spaced angles around the
// center, then passed to DrawPolygon().
//
// Because the result is rasterized onto a tile grid, very
// small polygons may appear slightly uneven.
//
// A minimum of three sides is required.
//
// ============================================================

world/proc/DrawNgon(
	var/list/map,
	var/cx,
	var/cy,
	var/radius,
	var/sides,
	var/rotation,
	var/tile
)
	if(radius <= 0)
		return

	if(sides < 3)
		return

	var/list/points = list()

	var/angle_step = 360 / sides

	for(var/i = 0, i < sides, i++)

		var/angle = rotation + (angle_step * i)

		var/x = round(
			cx + cos(angle) * radius
		)

		var/y = round(
			cy + sin(angle) * radius
		)

		points += list(
			list(x, y)
		)

	DrawPolygon(
		map,
		points,
		tile
	)

// ============================================================
// DRAW FILLED N-GON
// ============================================================
//
// Draws a filled regular polygon with an arbitrary number
// of sides.
//
// cx/cy represent the center of the polygon.
//
// radius represents the distance from the center to each
// polygon vertex.
//
// sides represents the number of sides:
//
//     3 = triangle
//     4 = square
//     5 = pentagon
//     6 = hexagon
//     8 = octagon
//     etc.
//
// rotation rotates the polygon in degrees.
//
// Vertices are calculated at evenly spaced angles around the
// center, then passed to DrawFilledPolygon().
//
// Because the result is rasterized onto a tile grid, very
// small polygons may appear slightly uneven.
//
// A minimum of three sides is required.
//
// ============================================================

world/proc/DrawFilledNgon(
	var/list/map,
	var/cx,
	var/cy,
	var/radius,
	var/sides,
	var/rotation,
	var/tile
)
	if(radius <= 0)
		return

	if(sides < 3)
		return

	var/list/points = list()

	var/angle_step = 360 / sides

	for(var/i = 0, i < sides, i++)

		var/angle = rotation + (angle_step * i)

		var/x = round(
			cx + cos(angle) * radius
		)

		var/y = round(
			cy + sin(angle) * radius
		)

		points += list(
			list(x, y)
		)

	DrawFilledPolygon(
		map,
		points,
		tile
	)

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
//     DrawCircleRing()
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

// ============================================================
// DRAW CIRCLE RING
// ============================================================
//
// Draws a solid ring by:
//
//     1. Drawing a filled outer circle into a temporary mask
//     2. Drawing a filled inner cutout circle into another mask
//     3. Copying only the tiles that are in the outer mask
//        but NOT in the inner mask
//
// inner_cut_radius:
//     Any tile at this radius or smaller is removed.
//
// outer_radius:
//     Any tile at this radius or smaller is kept.
//
// So the final ring is:
//
//     inner_cut_radius < distance <= outer_radius
//
// ============================================================

world/proc/DrawCircleRing(
	var/list/map,
	var/cx,
	var/cy,
	var/inner_cut_radius,
	var/outer_radius,
	var/tile
)
	if(outer_radius < 0)
		return

	if(inner_cut_radius >= outer_radius)
		return

	var/list/outer_mask = list()
	var/list/inner_mask = list()

	var/MASK_TILE = 1

	// Outer filled circle
	DrawFilledCircle(
		outer_mask,
		cx,
		cy,
		outer_radius,
		MASK_TILE
	)

	// Inner cutout circle
	if(inner_cut_radius >= 0)
		DrawFilledCircle(
			inner_mask,
			cx,
			cy,
			inner_cut_radius,
			MASK_TILE
		)

	// Bounding box
	var/min_x = cx - outer_radius
	var/max_x = cx + outer_radius
	var/min_y = cy - outer_radius
	var/max_y = cy + outer_radius

	for(var/draw_y = min_y, draw_y <= max_y, draw_y++)
		for(var/draw_x = min_x, draw_x <= max_x, draw_x++)

			if(MapGet(outer_mask, draw_x, draw_y) == MASK_TILE)
				if(MapGet(inner_mask, draw_x, draw_y) != MASK_TILE)
					MapSet(map, draw_x, draw_y, tile)


// ============================================================
// THICK CIRCLE
// ============================================================
//
// Draws a thick circle as a solid ring.
//
// radius:
//     Approximate centerline radius
//
// thickness:
//     Approximate radial thickness of the ring
//
// This proc uses DrawFilledCircle() masks instead of stacking
// multiple circle outlines, which avoids holes.
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

	// Approximate range of radii to keep.
	var/start_radius = radius - round((thickness - 1) / 2)
	var/end_radius = start_radius + thickness - 1

	if(start_radius < 0)
		start_radius = 0

	if(end_radius < start_radius)
		end_radius = start_radius

	DrawCircleRing(
		map,
		cx,
		cy,
		start_radius - 1,
		end_radius,
		tile
	)

// ============================================================
// THICK CIRCLE - INNER
// ============================================================
//
// Draws a thick circle where:
//
//     radius = OUTER radius
//
// thickness extends inward from that radius.
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

	var/outer_radius = radius
	var/inner_cut_radius = radius - thickness

	DrawCircleRing(
		map,
		cx,
		cy,
		inner_cut_radius,
		outer_radius,
		tile
	)


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

// ============================================================
// THICK CIRCLE - OUTER
// ============================================================
//
// Draws a thick circle where:
//
//     radius = INNER edge radius
//
// thickness extends outward from that radius.
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

	var/outer_radius = radius + thickness - 1
	var/inner_cut_radius = radius - 1

	DrawCircleRing(
		map,
		cx,
		cy,
		inner_cut_radius,
		outer_radius,
		tile
	)


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

	// Clamp thickness so it cannot exceed half of the
	// rectangle's smallest dimension.
	thickness = min(
		thickness,
		round(min(width, height) / 2)
	)

	if(thickness <= 0)
		return

	// --------------------------------------------------------
	// Top band
	// --------------------------------------------------------

	DrawFilledRectangle(
		map,
		x,
		y + height - thickness,
		width,
		thickness,
		tile
	)

	// --------------------------------------------------------
	// Bottom band
	// --------------------------------------------------------

	DrawFilledRectangle(
		map,
		x,
		y,
		width,
		thickness,
		tile
	)

	// --------------------------------------------------------
	// Left band
	//
	// Only fill the middle section so we don't unnecessarily
	// redraw the corners.
	// --------------------------------------------------------

	var/middle_height = height - (thickness * 2)

	if(middle_height > 0)

		DrawFilledRectangle(
			map,
			x,
			y + thickness,
			thickness,
			middle_height,
			tile
		)

		// ----------------------------------------------------
		// Right band
		// ----------------------------------------------------

		DrawFilledRectangle(
			map,
			x + width - thickness,
			y + thickness,
			thickness,
			middle_height,
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

	// Clamp radius so the corners cannot overlap.
	radius = min(
		radius,
		round((min(width, height) - 1) / 2)
	)

	if(radius <= 0)
		DrawRectangle(
			map,
			x,
			y,
			width,
			height,
			tile
		)
		return

	var/left = x
	var/right = x + width - 1
	var/bottom = y
	var/top = y + height - 1

	var/radius_squared = radius * radius

	// --------------------------------------------------------
	// Top and bottom flat sections.
	// --------------------------------------------------------

	DrawHorizontalLine(
		map,
		left + radius,
		bottom,
		(width - (radius * 2)),
		tile
	)

	DrawHorizontalLine(
		map,
		left + radius,
		top,
		(width - (radius * 2)),
		tile
	)

	// --------------------------------------------------------
	// Middle vertical sections.
	// --------------------------------------------------------

	DrawVerticalLine(
		map,
		left,
		bottom + radius,
		(height - (radius * 2)),
		tile
	)

	DrawVerticalLine(
		map,
		right,
		bottom + radius,
		(height - (radius * 2)),
		tile
	)

	// --------------------------------------------------------
	// Rounded corners.
	//
	// Generate one corner profile and mirror it into all four
	// corners. This guarantees that every corner has exactly
	// the same rasterization.
	// --------------------------------------------------------

	var/previous_inset = radius

	for(var/edge_y = 0, edge_y <= radius, edge_y++)

		// Distance from the corner-circle center.
		var/circle_y = radius - edge_y

		// Find the horizontal extent of the circle at this row.
		var/circle_x = round(
			sqrt(
				radius_squared - (circle_y * circle_y)
			)
		)

		// Convert that into distance inward from the rectangle
		// edge.
		var/inset = radius - circle_x

		// Coordinates mirrored across all four corners.
		var/left_x = left + inset
		var/right_x = right - inset

		var/bottom_y = bottom + edge_y
		var/top_y = top - edge_y

		// Main corner pixels.
		DrawPixel(map, left_x, bottom_y, tile)
		DrawPixel(map, right_x, bottom_y, tile)

		DrawPixel(map, left_x, top_y, tile)
		DrawPixel(map, right_x, top_y, tile)

		// ----------------------------------------------------
		// If the corner moves sideways by more than one tile,
		// connect the step horizontally.
		//
		// Do this symmetrically on all four corners.
		// ----------------------------------------------------

		if(inset != previous_inset)

			var/min_inset = min(inset, previous_inset)
			var/max_inset = max(inset, previous_inset)
			var/step_width = (max_inset - min_inset) + 1

			// Bottom-left
			DrawHorizontalLine(
				map,
				left + min_inset,
				bottom_y,
				step_width,
				tile
			)

			// Bottom-right
			DrawHorizontalLine(
				map,
				right - max_inset,
				bottom_y,
				step_width,
				tile
			)

			// Top-left
			DrawHorizontalLine(
				map,
				left + min_inset,
				top_y,
				step_width,
				tile
			)

			// Top-right
			DrawHorizontalLine(
				map,
				right - max_inset,
				top_y,
				step_width,
				tile
			)

		previous_inset = inset

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

	// --------------------------------------------------------
	// Capture the exact outline generated by
	// DrawRoundedRectangle().
	// --------------------------------------------------------

	var/list/mask = list()
	var/MASK_TILE = 1

	DrawRoundedRectangle(
		mask,
		x,
		y,
		width,
		height,
		radius,
		MASK_TILE
	)

	// --------------------------------------------------------
	// Scan each row of the rectangle.
	//
	// Find the leftmost and rightmost outline pixels, then
	// fill everything between them.
	// --------------------------------------------------------

	var/right = x + width - 1
	var/top = y + height - 1

	for(var/draw_y = y, draw_y <= top, draw_y++)

		var/start_x = null
		var/end_x = null

		for(var/draw_x = x, draw_x <= right, draw_x++)

			if(MapGet(mask, draw_x, draw_y) == MASK_TILE)

				if(isnull(start_x))
					start_x = draw_x

				end_x = draw_x

		// If this row contains part of the rounded outline,
		// fill everything between the two edges.
		if(!isnull(start_x) && !isnull(end_x))

			DrawHorizontalLine(
				map,
				start_x,
				draw_y,
				(end_x - start_x) + 1,
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

	// No rounding requested.
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
	// STEP 1
	//
	// Generate the normal filled triangle.
	// --------------------------------------------------------

	var/list/original_mask = list()
	var/MASK_TILE = 1

	DrawFilledTriangle(
		original_mask,
		cx,
		y,
		base,
		height,
		MASK_TILE
	)

	// Bounding area of the triangle.
	var/left_x = cx - ((base - 1) / 2)
	left_x = round(left_x)

	var/right_x = left_x + base - 1

	var/bottom_y = y
	var/top_y = y + height - 1

	var/radius_squared = radius * radius


	// --------------------------------------------------------
	// STEP 2 - ERODE
	//
	// Remove tiles near the outside edge.
	//
	// A tile survives only if every tile within the circular
	// radius around it is also inside the original triangle.
	// --------------------------------------------------------

	var/list/eroded_mask = list()

	for(var/check_y = bottom_y, check_y <= top_y, check_y++)
		for(var/check_x = left_x, check_x <= right_x, check_x++)

			if(MapGet(original_mask, check_x, check_y) != MASK_TILE)
				continue

			var/keep_tile = TRUE

			for(var/offset_y = -radius, offset_y <= radius, offset_y++)
				for(var/offset_x = -radius, offset_x <= radius, offset_x++)

					// Only examine points inside the circular
					// rounding radius.
					if((offset_x * offset_x) + (offset_y * offset_y) > radius_squared )
						continue

					if(
						MapGet(
							original_mask,
							check_x + offset_x,
							check_y + offset_y
						) != MASK_TILE
					)
						keep_tile = FALSE
						break

				if(!keep_tile)
					break

			if(keep_tile)
				MapSet(
					eroded_mask,
					check_x,
					check_y,
					MASK_TILE
				)


	// --------------------------------------------------------
	// STEP 3 - DILATE
	//
	// Expand the smaller triangle back outward using a
	// circular brush.
	//
	// This restores the straight edges while leaving the
	// corners rounded.
	// --------------------------------------------------------

	var/list/rounded_mask = list()

	for(var/key in eroded_mask)

		var/list/coords = splittext(key, ",")
		var/source_x = text2num(coords[1])
		var/source_y = text2num(coords[2])

		for(var/offset_y = -radius, offset_y <= radius, offset_y++)
			for(var/offset_x = -radius, offset_x <= radius, offset_x++)

				if((offset_x * offset_x) + (offset_y * offset_y) > radius_squared )
					continue

				var/draw_x = source_x + offset_x
				var/draw_y = source_y + offset_y

				// Keep the rounded result inside the original
				// triangle.
				if(
					MapGet(
						original_mask,
						draw_x,
						draw_y
					) == MASK_TILE
				)
					MapSet(
						rounded_mask,
						draw_x,
						draw_y,
						MASK_TILE
					)


	// --------------------------------------------------------
	// STEP 4 - EXTRACT THE OUTLINE
	//
	// A tile is part of the outline if at least one of its
	// four cardinal neighbours is outside the rounded shape.
	// --------------------------------------------------------

	for(var/key in rounded_mask)

		var/list/coords = splittext(key, ",")
		var/draw_x = text2num(coords[1])
		var/draw_y = text2num(coords[2])

		var/is_edge = FALSE

		if(MapGet(rounded_mask, draw_x + 1, draw_y) != MASK_TILE)
			is_edge = TRUE

		else if(MapGet(rounded_mask, draw_x - 1, draw_y) != MASK_TILE)
			is_edge = TRUE

		else if(MapGet(rounded_mask, draw_x, draw_y + 1) != MASK_TILE)
			is_edge = TRUE

		else if(MapGet(rounded_mask, draw_x, draw_y - 1) != MASK_TILE)
			is_edge = TRUE

		if(is_edge)
			DrawPixel(
				map,
				draw_x,
				draw_y,
				tile
			)


// ============================================================
// DRAW MAZE FROM CENTERPOINT
// ============================================================
//
// Generates a solvable rectangular maze centered around cx/cy.
//
// width / height:
//     Number of logical maze cells.
//
// wallthickness:
//     Thickness of walls in tiles.
//
// corridorthickness:
//     Width/height of each walkable maze cell in tiles.
//
// tilefloor:
//     Tile used for walkable maze space.
//
// tilewall:
//     Tile used for maze walls.
//
// The maze is generated as a "perfect maze":
//
//     - Every cell is reachable.
//     - There are no isolated sections.
//     - There is exactly one path between any two cells.
//
// The generation begins at the center cell.
//
// One entrance is then opened on a random outer edge.
//
// Returns:
//
//     list(
//         "entrance_x" = ...,
//         "entrance_y" = ...,
//         "center_x"   = ...,
//         "center_y"   = ...,
//         "tile_width" = ...,
//         "tile_height" = ...
//     )
//
// ============================================================

world/proc/DrawMazeFromCenterpoint(
	var/list/map,
	var/cx,
	var/cy,
	var/width,
	var/height,
	var/wallthickness,
	var/corridorthickness,
	var/tilefloor,
	var/tilewall,
	var/tilecenter
)
	if(width <= 0 || height <= 0)
		return null

	if(wallthickness <= 0 || corridorthickness <= 0)
		return null


	// ========================================================
	// CALCULATE PHYSICAL MAZE SIZE
	// ========================================================

	var/tile_width = \
		(width * corridorthickness) + \
		((width + 1) * wallthickness)

	var/tile_height = \
		(height * corridorthickness) + \
		((height + 1) * wallthickness)


	// Bottom-left corner of the entire maze.
	var/start_x = cx - round((tile_width - 1) / 2)
	var/start_y = cy - round((tile_height - 1) / 2)


	// ========================================================
	// CREATE SOLID WALL BLOCK
	// ========================================================
	//
	// Rather than drawing every individual maze wall, start
	// with one solid rectangle of wall and carve floors into it.
	//
	// This makes wall thickness very easy to control.
	// ========================================================

	DrawFilledRectangle(
		map,
		start_x,
		start_y,
		tile_width,
		tile_height,
		tilewall
	)


	// ========================================================
	// MAZE DATA
	// ========================================================
	//
	// visited:
	//     Tracks which logical cells have been generated.
	//
	// connections:
	//     Stores which neighbouring cells are connected.
	//
	// Keys use:
	//
	//     "x,y"
	//
	// Connection flags:
	//
	//     1 = North
	//     2 = East
	//     4 = South
	//     8 = West
	//
	// ========================================================

	var/list/visited = list()
	var/list/connections = list()


	// ========================================================
	// FIND CENTER LOGICAL CELL
	// ========================================================

	var/maze_cx = round((width + 1) / 2)
	var/maze_cy = round((height + 1) / 2)


	// ========================================================
	// RANDOMIZED DEPTH-FIRST SEARCH
	// ========================================================

	var/list/stack = list()

	var/start_key = "[maze_cx],[maze_cy]"

	visited[start_key] = TRUE
	stack += list(list(maze_cx, maze_cy))


	while(stack.len)

		var/list/current = stack[stack.len]

		var/current_x = current[1]
		var/current_y = current[2]

		var/list/options = list()


		// ----------------------------------------------------
		// NORTH
		// ----------------------------------------------------

		if(current_y < height)

			var/key = "[current_x],[current_y + 1]"

			if(!visited[key])
				options += list(
					list(
						current_x,
						current_y + 1,
						1,      // Current cell: north
						4       // New cell: south
					)
				)


		// ----------------------------------------------------
		// EAST
		// ----------------------------------------------------

		if(current_x < width)

			var/key = "[current_x + 1],[current_y]"

			if(!visited[key])
				options += list(
					list(
						current_x + 1,
						current_y,
						2,      // Current cell: east
						8       // New cell: west
					)
				)


		// ----------------------------------------------------
		// SOUTH
		// ----------------------------------------------------

		if(current_y > 1)

			var/key = "[current_x],[current_y - 1]"

			if(!visited[key])
				options += list(
					list(
						current_x,
						current_y - 1,
						4,      // Current cell: south
						1       // New cell: north
					)
				)


		// ----------------------------------------------------
		// WEST
		// ----------------------------------------------------

		if(current_x > 1)

			var/key = "[current_x - 1],[current_y]"

			if(!visited[key])
				options += list(
					list(
						current_x - 1,
						current_y,
						8,      // Current cell: west
						2       // New cell: east
					)
				)


		// ----------------------------------------------------
		// DEAD END
		// ----------------------------------------------------

		if(!options.len)

			stack.Cut(stack.len, stack.len + 1)
			continue


		// ----------------------------------------------------
		// PICK RANDOM UNVISITED NEIGHBOUR
		// ----------------------------------------------------

		var/list/chosen = options[rand(1, options.len)]

		var/next_x = chosen[1]
		var/next_y = chosen[2]

		var/current_direction = chosen[3]
		var/opposite_direction = chosen[4]

		var/current_key = "[current_x],[current_y]"
		var/next_key = "[next_x],[next_y]"


		// Add connection to current cell.
		var/current_connections = connections[current_key]

		if(isnull(current_connections))
			current_connections = 0

		current_connections |= current_direction

		connections[current_key] = current_connections


		// Add reciprocal connection.
		var/next_connections = connections[next_key]

		if(isnull(next_connections))
			next_connections = 0

		next_connections |= opposite_direction

		connections[next_key] = next_connections


		visited[next_key] = TRUE

		stack += list(
			list(
				next_x,
				next_y
			)
		)


	// ========================================================
	// CARVE MAZE CELLS
	// ========================================================

	for(var/maze_x = 1, maze_x <= width, maze_x++)
		for(var/maze_y = 1, maze_y <= height, maze_y++)

			// Physical bottom-left corner of this maze cell.
			var/cell_x = \
				start_x + \
				wallthickness + \
				((maze_x - 1) * \
				(corridorthickness + wallthickness))

			var/cell_y = \
				start_y + \
				wallthickness + \
				((maze_y - 1) * \
				(corridorthickness + wallthickness))


			// ------------------------------------------------
			// Carve the cell itself.
			// ------------------------------------------------

			DrawFilledRectangle(
				map,
				cell_x,
				cell_y,
				corridorthickness,
				corridorthickness,
				tilefloor
			)


			var/key = "[maze_x],[maze_y]"
			var/cell_connections = connections[key]

			if(isnull(cell_connections))
				cell_connections = 0


			// ------------------------------------------------
			// NORTH CONNECTION
			// ------------------------------------------------

			if(cell_connections & 1)

				DrawFilledRectangle(
					map,
					cell_x,
					cell_y + corridorthickness,
					corridorthickness,
					wallthickness,
					tilefloor
				)


			// ------------------------------------------------
			// EAST CONNECTION
			// ------------------------------------------------

			if(cell_connections & 2)

				DrawFilledRectangle(
					map,
					cell_x + corridorthickness,
					cell_y,
					wallthickness,
					corridorthickness,
					tilefloor
				)


			// South and west do not need to be carved here.
			//
			// Their neighbouring cells will carve those walls
			// through their north/east connections.


	// ========================================================
	// CREATE RANDOM ENTRANCE
	// ========================================================

	var/entrance_side = rand(1, 4)

	var/entrance_x
	var/entrance_y


	switch(entrance_side)

		// ----------------------------------------------------
		// NORTH
		// ----------------------------------------------------

		if(1)

			var/entrance_cell = rand(1, width)

			entrance_x = \
				start_x + \
				wallthickness + \
				((entrance_cell - 1) * \
					(corridorthickness + wallthickness))

			entrance_y = start_y + tile_height - wallthickness

			DrawFilledRectangle(
				map,
				entrance_x,
				entrance_y,
				corridorthickness,
				wallthickness,
				tilefloor
			)


		// ----------------------------------------------------
		// EAST
		// ----------------------------------------------------

		if(2)

			var/entrance_cell = rand(1, height)

			entrance_x = start_x + tile_width - wallthickness

			entrance_y = \
				start_y + \
				wallthickness + \
				((entrance_cell - 1) * \
					(corridorthickness + wallthickness))

			DrawFilledRectangle(
				map,
				entrance_x,
				entrance_y,
				wallthickness,
				corridorthickness,
				tilefloor
			)


		// ----------------------------------------------------
		// SOUTH
		// ----------------------------------------------------

		if(3)

			var/entrance_cell = rand(1, width)

			entrance_x = \
				start_x + \
				wallthickness + \
				((entrance_cell - 1) * \
					(corridorthickness + wallthickness))

			entrance_y = start_y

			DrawFilledRectangle(
				map,
				entrance_x,
				entrance_y,
				corridorthickness,
				wallthickness,
				tilefloor
			)


		// ----------------------------------------------------
		// WEST
		// ----------------------------------------------------

		if(4)

			var/entrance_cell = rand(1, height)

			entrance_x = start_x

			entrance_y = \
				start_y + \
				wallthickness + \
				((entrance_cell - 1) * \
					(corridorthickness + wallthickness))

			DrawFilledRectangle(
				map,
				entrance_x,
				entrance_y,
				wallthickness,
				corridorthickness,
				tilefloor
			)
	// ========================================================
	// MARK CENTER CELL
	// ========================================================
	//
	// Repaint the logical center cell using tilecenter.
	//
	// The passages leading into the center remain tilefloor;
	// only the actual corridor-sized center cell is marked.
	// ========================================================

	var/center_cell_x = \
		start_x + \
		wallthickness + \
		((maze_cx - 1) * \
			(corridorthickness + wallthickness))

	var/center_cell_y = \
		start_y + \
		wallthickness + \
		((maze_cy - 1) * \
			(corridorthickness + wallthickness))

	DrawFilledRectangle(
		map,
		center_cell_x,
		center_cell_y,
		corridorthickness,
		corridorthickness,
		tilecenter
	)

	// ========================================================
	// RETURN USEFUL INFORMATION
	// ========================================================

	return list(
		"entrance_x" = entrance_x,
		"entrance_y" = entrance_y,

		"center_x" = center_cell_x + round((corridorthickness - 1) / 2),
		"center_y" = center_cell_y + round((corridorthickness - 1) / 2),

		"tile_width" = tile_width,
		"tile_height" = tile_height
	)


// ============================================================
// DRAW FOREST MAZE PATH
// ============================================================
//
// Generates a highly-branched forest path network inside a
// supplied rectangular area.
//
// x / y:
//     TOP-LEFT corner of the available area.
//
// max_width / max_height:
//     Maximum physical size, in map tiles.
//
// Walls are always 2 tiles thick.
//
// corridorthickness:
//     Width of paths in tiles.
//     Defaults to 4.
//
// start_side / end_side:
//     Optional:
//         "NORTH"
//         "EAST"
//         "SOUTH"
//         "WEST"
//
// start_cell / end_cell:
//     Optional logical cell along that edge.
//     If omitted or invalid, a random cell is selected.
//
// loopchance:
//     Percentage chance of opening an additional wall between
//     adjacent maze cells after the main maze is generated.
//
//     0  = perfect maze
//     15 = moderately interconnected forest paths
//     30 = very interconnected
//
// Returns useful information including:
//     actual dimensions
//     start/end coordinates
//     logical dimensions
//     tree placement list
//
// Tree placements are NOT spawned here. They are returned so
// actual objects can be created later during the map commit.
//
// ============================================================

world/proc/DrawForestMazePath(
	var/list/map,
	var/x,
	var/y,
	var/max_width,
	var/max_height,
	var/tilefloor,
	var/tilewall,
	var/corridorthickness = 4,
	var/start_side = null,
	var/start_cell = null,
	var/end_side = null,
	var/end_cell = null,
	var/loopchance = 15
)
	var/wallthickness = 2

	if(max_width <= 0 || max_height <= 0)
		return null

	if(corridorthickness <= 0)
		corridorthickness = 4


	// ========================================================
	// CALCULATE HOW MANY LOGICAL CELLS FIT
	// ========================================================
	//
	// Physical size:
	//
	//     cells * corridor
	//     +
	//     (cells + 1) * wall
	//
	// ========================================================

	var/cell_step = corridorthickness + wallthickness

	var/maze_width = round(
		(max_width - wallthickness) / cell_step
	)

	var/maze_height = round(
		(max_height - wallthickness) / cell_step
	)

	if(maze_width < 1 || maze_height < 1)
		return null


	// Actual physical dimensions used.
	var/tile_width = \
		(maze_width * corridorthickness) + \
		((maze_width + 1) * wallthickness)

	var/tile_height = \
		(maze_height * corridorthickness) + \
		((maze_height + 1) * wallthickness)


	// Top-left is supplied by x/y.
	var/left = x
	var/top = y

	var/right = left + tile_width - 1
	var/bottom = top - tile_height + 1


	// ========================================================
	// VALIDATE / CHOOSE START SIDE
	// ========================================================

	var/list/valid_sides = list(
		"NORTH",
		"EAST",
		"SOUTH",
		"WEST"
	)

	if(!(start_side in valid_sides))
		start_side = valid_sides[rand(1, valid_sides.len)]


	// ========================================================
	// VALIDATE / CHOOSE END SIDE
	// ========================================================
	//
	// If random, deliberately choose a different edge from
	// the entrance so the trail crosses the forest region.
	// ========================================================

	if(!(end_side in valid_sides))

		var/list/end_choices = valid_sides.Copy()
		end_choices -= start_side

		end_side = end_choices[rand(1, end_choices.len)]


	// ========================================================
	// DETERMINE HOW MANY CELLS EACH EDGE CONTAINS
	// ========================================================

	var/start_max

	if(start_side == "NORTH" || start_side == "SOUTH")
		start_max = maze_width
	else
		start_max = maze_height

	if(isnull(start_cell) || start_cell < 1 || start_cell > start_max)
		start_cell = rand(1, start_max)


	var/end_max

	if(end_side == "NORTH" || end_side == "SOUTH")
		end_max = maze_width
	else
		end_max = maze_height

	if(isnull(end_cell) || end_cell < 1 || end_cell > end_max)
		end_cell = rand(1, end_max)


	// ========================================================
	// CONVERT ENTRANCE INTO A LOGICAL MAZE CELL
	// ========================================================

	var/start_maze_x
	var/start_maze_y

	switch(start_side)

		if("NORTH")
			start_maze_x = start_cell
			start_maze_y = maze_height

		if("EAST")
			start_maze_x = maze_width
			start_maze_y = start_cell

		if("SOUTH")
			start_maze_x = start_cell
			start_maze_y = 1

		if("WEST")
			start_maze_x = 1
			start_maze_y = start_cell


	// ========================================================
	// CREATE TEMPORARY WALL MASK
	// ========================================================
	//
	// Start with the entire maze area as wall.
	// Paths are carved into this mask afterward.
	//
	// ========================================================

	var/list/maze_map = list()

	for(var/draw_x = left, draw_x <= right, draw_x++)
		for(var/draw_y = bottom, draw_y <= top, draw_y++)
			MapSet(
				maze_map,
				draw_x,
				draw_y,
				tilewall
			)


	// ========================================================
	// MAZE CONNECTION DATA
	// ========================================================
	//
	// Direction flags:
	//
	//     1 = NORTH
	//     2 = EAST
	//     4 = SOUTH
	//     8 = WEST
	//
	// ========================================================

	var/list/visited = list()
	var/list/connections = list()
	var/list/frontier = list()


	// ========================================================
	// START PRIM'S ALGORITHM AT THE ENTRANCE CELL
	// ========================================================

	var/start_key = "[start_maze_x],[start_maze_y]"

	visited[start_key] = TRUE


	// ========================================================
	// ADD INITIAL FRONTIER
	// ========================================================

	if(start_maze_y < maze_height)
		frontier += list(
			list(
				start_maze_x,
				start_maze_y,
				start_maze_x,
				start_maze_y + 1,
				1,
				4
			)
		)

	if(start_maze_x < maze_width)
		frontier += list(
			list(
				start_maze_x,
				start_maze_y,
				start_maze_x + 1,
				start_maze_y,
				2,
				8
			)
		)

	if(start_maze_y > 1)
		frontier += list(
			list(
				start_maze_x,
				start_maze_y,
				start_maze_x,
				start_maze_y - 1,
				4,
				1
			)
		)

	if(start_maze_x > 1)
		frontier += list(
			list(
				start_maze_x,
				start_maze_y,
				start_maze_x - 1,
				start_maze_y,
				8,
				2
			)
		)


	// ========================================================
	// RANDOMIZED PRIM'S MAZE
	// ========================================================

	while(frontier.len)

		var/frontier_index = rand(1, frontier.len)
		var/list/edge = frontier[frontier_index]

		frontier.Cut(
			frontier_index,
			frontier_index + 1
		)

		var/from_x = edge[1]
		var/from_y = edge[2]

		var/to_x = edge[3]
		var/to_y = edge[4]

		var/from_direction = edge[5]
		var/to_direction = edge[6]

		var/to_key = "[to_x],[to_y]"

		// Ignore frontier edges leading into cells that
		// have already been incorporated.
		if(visited[to_key])
			continue


		var/from_key = "[from_x],[from_y]"

		var/from_connections = connections[from_key]

		if(isnull(from_connections))
			from_connections = 0

		from_connections |= from_direction
		connections[from_key] = from_connections


		var/to_connections = connections[to_key]

		if(isnull(to_connections))
			to_connections = 0

		to_connections |= to_direction
		connections[to_key] = to_connections


		visited[to_key] = TRUE


		// ----------------------------------------------------
		// ADD NEW CELL'S NEIGHBOURS TO THE FRONTIER
		// ----------------------------------------------------

		if(to_y < maze_height)

			var/key = "[to_x],[to_y + 1]"

			if(!visited[key])
				frontier += list(
					list(
						to_x,
						to_y,
						to_x,
						to_y + 1,
						1,
						4
					)
				)


		if(to_x < maze_width)

			var/key = "[to_x + 1],[to_y]"

			if(!visited[key])
				frontier += list(
					list(
						to_x,
						to_y,
						to_x + 1,
						to_y,
						2,
						8
					)
				)


		if(to_y > 1)

			var/key = "[to_x],[to_y - 1]"

			if(!visited[key])
				frontier += list(
					list(
						to_x,
						to_y,
						to_x,
						to_y - 1,
						4,
						1
					)
				)


		if(to_x > 1)

			var/key = "[to_x - 1],[to_y]"

			if(!visited[key])
				frontier += list(
					list(
						to_x,
						to_y,
						to_x - 1,
						to_y,
						8,
						2
					)
				)


	// ========================================================
	// ADD EXTRA CONNECTIONS
	// ========================================================
	//
	// Prim's gives us a highly branched spanning tree.
	//
	// Opening some additional walls gives the forest paths
	// loops and alternate routes.
	//
	// Only EAST and NORTH are considered so each shared wall
	// is checked once.
	//
	// ========================================================

	loopchance = max(0, min(loopchance, 100))

	for(var/maze_x = 1, maze_x <= maze_width, maze_x++)
		for(var/maze_y = 1, maze_y <= maze_height, maze_y++)

			var/key = "[maze_x],[maze_y]"

			var/cell_connections = connections[key]

			if(isnull(cell_connections))
				cell_connections = 0


			// EAST
			if(maze_x < maze_width)

				if(!(cell_connections & 2))

					if(prob(loopchance))

						cell_connections |= 2

						var/east_key = "[maze_x + 1],[maze_y]"
						var/east_connections = connections[east_key]

						if(isnull(east_connections))
							east_connections = 0

						east_connections |= 8

						connections[east_key] = east_connections


			// NORTH
			if(maze_y < maze_height)

				if(!(cell_connections & 1))

					if(prob(loopchance))

						cell_connections |= 1

						var/north_key = "[maze_x],[maze_y + 1]"
						var/north_connections = connections[north_key]

						if(isnull(north_connections))
							north_connections = 0

						north_connections |= 4

						connections[north_key] = north_connections


			connections[key] = cell_connections


	// ========================================================
	// CARVE CELLS AND PASSAGES
	// ========================================================

	for(var/maze_x = 1, maze_x <= maze_width, maze_x++)
		for(var/maze_y = 1, maze_y <= maze_height, maze_y++)

			var/cell_x = \
				left + \
				wallthickness + \
				((maze_x - 1) * cell_step)

			var/cell_y = \
				bottom + \
				wallthickness + \
				((maze_y - 1) * cell_step)


			// Main corridor cell.
			DrawFilledRectangle(
				maze_map,
				cell_x,
				cell_y,
				corridorthickness,
				corridorthickness,
				tilefloor
			)


			var/key = "[maze_x],[maze_y]"
			var/cell_connections = connections[key]

			if(isnull(cell_connections))
				cell_connections = 0


			// NORTH passage
			if(cell_connections & 1)

				DrawFilledRectangle(
					maze_map,
					cell_x,
					cell_y + corridorthickness,
					corridorthickness,
					wallthickness,
					tilefloor
				)


			// EAST passage
			if(cell_connections & 2)

				DrawFilledRectangle(
					maze_map,
					cell_x + corridorthickness,
					cell_y,
					wallthickness,
					corridorthickness,
					tilefloor
				)


	// ========================================================
	// OPEN START
	// ========================================================

	var/start_x
	var/start_y

	switch(start_side)

		if("NORTH")

			start_x = \
				left + \
				wallthickness + \
				((start_cell - 1) * cell_step)

			start_y = top - wallthickness + 1

			DrawFilledRectangle(
				maze_map,
				start_x,
				start_y,
				corridorthickness,
				wallthickness,
				tilefloor
			)


		if("SOUTH")

			start_x = \
				left + \
				wallthickness + \
				((start_cell - 1) * cell_step)

			start_y = bottom

			DrawFilledRectangle(
				maze_map,
				start_x,
				start_y,
				corridorthickness,
				wallthickness,
				tilefloor
			)


		if("EAST")

			start_x = right - wallthickness + 1

			start_y = \
				bottom + \
					wallthickness + \
					((start_cell - 1) * cell_step)

			DrawFilledRectangle(
				maze_map,
				start_x,
				start_y,
				wallthickness,
				corridorthickness,
				tilefloor
			)


		if("WEST")

			start_x = left

			start_y = \
				bottom + \
					wallthickness + \
					((start_cell - 1) * cell_step)

			DrawFilledRectangle(
				maze_map,
				start_x,
				start_y,
				wallthickness,
				corridorthickness,
				tilefloor
			)


	// ========================================================
	// OPEN END
	// ========================================================

	var/end_x
	var/end_y

	switch(end_side)

		if("NORTH")

			end_x = \
				left + \
					wallthickness + \
					((end_cell - 1) * cell_step)

			end_y = top - wallthickness + 1

			DrawFilledRectangle(
				maze_map,
				end_x,
				end_y,
				corridorthickness,
				wallthickness,
				tilefloor
			)


		if("SOUTH")

			end_x = \
				left + \
					wallthickness + \
					((end_cell - 1) * cell_step)

			end_y = bottom

			DrawFilledRectangle(
				maze_map,
				end_x,
				end_y,
				corridorthickness,
				wallthickness,
				tilefloor
			)


		if("EAST")

			end_x = right - wallthickness + 1

			end_y = \
				bottom + \
					wallthickness + \
					((end_cell - 1) * cell_step)

			DrawFilledRectangle(
				maze_map,
				end_x,
				end_y,
				wallthickness,
				corridorthickness,
				tilefloor
			)


		if("WEST")

			end_x = left

			end_y = \
				bottom + \
					wallthickness + \
					((end_cell - 1) * cell_step)

			DrawFilledRectangle(
				maze_map,
				end_x,
				end_y,
				wallthickness,
				corridorthickness,
				tilefloor
			)


	// ========================================================
	// COPY GENERATED FOREST MAZE ONTO DESTINATION MAP
	// ========================================================

	for(var/draw_x = left, draw_x <= right, draw_x++)
		for(var/draw_y = bottom, draw_y <= top, draw_y++)

			MapSet(
				map,
				draw_x,
				draw_y,
				MapGet(
					maze_map,
					draw_x,
					draw_y
				)
			)


	// ========================================================
	// TREE PACKING
	// ========================================================
	//
	// Wall areas are packed greedily:
	//
	//     2x2 -> /obj/tree/Tree1
	//     1x2 -> /obj/tree/ThinTree1
	//     1x1 -> /obj/tree/SmallTree1
	//
	// Placements use the SOUTH-WEST tile as their anchor.
	//
	// They are returned instead of spawned immediately so
	// procedural generation remains separate from committing
	// actual map objects.
	//
	// ========================================================

	var/list/tree_placements = list()
	var/list/tree_used = list()


	for(var/tree_y = bottom, tree_y <= top, tree_y++)
		for(var/tree_x = left, tree_x <= right, tree_x++)

			var/current_key = MapKey(tree_x, tree_y)

			if(tree_used[current_key])
				continue

			if(MapGet(maze_map, tree_x, tree_y) != tilewall)
				continue


			// ------------------------------------------------
			// TRY 2x2 TREE
			// ------------------------------------------------

			if(
				tree_x + 1 <= right && tree_y + 1 <= top
			)

				var/key_e = MapKey(tree_x + 1, tree_y)
				var/key_n = MapKey(tree_x, tree_y + 1)
				var/key_ne = MapKey(tree_x + 1, tree_y + 1)

				if(
					!tree_used[key_e] && !tree_used[key_n] && !tree_used[key_ne] && MapGet(maze_map, tree_x + 1, tree_y) == tilewall && MapGet(maze_map, tree_x, tree_y + 1) == tilewall && MapGet(maze_map, tree_x + 1, tree_y + 1) == tilewall
				)

					tree_placements += list(
						list(
							"type" = /obj/tree/Tree1,
							"x" = tree_x,
							"y" = tree_y
						)
					)

					tree_used[current_key] = TRUE
					tree_used[key_e] = TRUE
					tree_used[key_n] = TRUE
					tree_used[key_ne] = TRUE

					continue


			// ------------------------------------------------
			// TRY VERTICAL 1x2 TREE
			// ------------------------------------------------

			if(tree_y + 1 <= top)

				var/key_n = MapKey(tree_x, tree_y + 1)

				if(
					!tree_used[key_n] && MapGet( maze_map, tree_x, tree_y + 1 ) == tilewall
				)

					tree_placements += list(
						list(
							"type" = /obj/tree/ThinTree1,
							"x" = tree_x,
							"y" = tree_y
						)
					)

					tree_used[current_key] = TRUE
					tree_used[key_n] = TRUE

					continue


			// ------------------------------------------------
			// 1x1 TREE
			// ------------------------------------------------

			tree_placements += list(
				list(
					"type" = /obj/tree/SmallTree1,
					"x" = tree_x,
					"y" = tree_y
				)
			)

			tree_used[current_key] = TRUE


	// ========================================================
	// RETURN RESULT
	// ========================================================

	return list(
		"start_x" = start_x,
		"start_y" = start_y,
		"start_side" = start_side,
		"start_cell" = start_cell,

		"end_x" = end_x,
		"end_y" = end_y,
		"end_side" = end_side,
		"end_cell" = end_cell,

		"width" = tile_width,
		"height" = tile_height,

		"maze_width" = maze_width,
		"maze_height" = maze_height,

		"trees" = tree_placements
	)

// ============================================================
// COMMIT FOREST MAZE TREES
// ============================================================
//
// Creates the tree objects calculated by
// DrawForestMazePath().
//
// Call this AFTER the generated turf map has been committed.
//
// ============================================================

world/proc/CommitForestMazeTrees(
	var/list/tree_placements,
	var/z = 1
)
	if(!tree_placements)
		return

	for(var/list/tree_data in tree_placements)

		var/tree_type = tree_data["type"]
		var/tree_x = tree_data["x"]
		var/tree_y = tree_data["y"]

		var/turf/T = locate(
			tree_x,
			tree_y,
			z
		)

		if(!T)
			continue

		new tree_type(T)

// ============================================================
// DRAW MAP ONTO MAP
// ============================================================
//
// Copies one generated map list onto another.
//
// source_map:
//     The map being copied FROM.
//
// dest_map:
//     The map being copied TO.
//
// dest_x / dest_y:
//     The destination position where source tile (1,1)
//     should be placed.
//
// Any source tile equal to TILE_EMPTY is ignored.
//
// This allows temporary/generated sub-maps to be stamped onto
// a larger map without overwriting existing tiles with empty
// space.
//
// Example:
//
//     var/list/room = list()
//     MapSet(room, 1, 1, TILE_GRASS)
//     MapSet(room, 2, 1, TILE_GRASS)
//
//     DrawMapOntoMap(
//         world_map,
//         room,
//         50,
//         75
//     )
//
// This would place:
//
//     room(1,1) -> world_map(50,75)
//     room(2,1) -> world_map(51,75)
//
// ============================================================

world/proc/DrawMapOntoMap(
	var/list/dest_map,
	var/list/source_map,
	var/dest_x,
	var/dest_y
)
	if(!dest_map || !source_map)
		return

	for(var/key in source_map)

		var/list/coords = splittext(key, ",")

		if(!coords || coords.len < 2)
			continue

		var/source_x = text2num(coords[1])
		var/source_y = text2num(coords[2])

		var/tile = source_map[key]

		// Skip empty tiles so the source map only stamps
		// meaningful content.
		if(tile == TILE_EMPTY)
			continue

		// Convert source-local coordinates into destination
		// coordinates.
		var/target_x = dest_x + source_x - 1
		var/target_y = dest_y + source_y - 1

		// Only place tiles that fit on the main map.
		if(!MapInBounds(target_x, target_y))
			continue

		MapSet(
			dest_map,
			target_x,
			target_y,
			tile
		)

// ============================================================
// REPLACE TILE IN REGION
// ============================================================
//
// Replaces every occurrence of old_tile with new_tile inside
// a rectangular region.
//
// x / y:
//     Bottom-left corner of the region.
//
// width / height:
//     Size of the region.
//
// Tiles outside the region are untouched.
//
// Returns the number of tiles replaced.
//
// ============================================================

world/proc/ReplaceTileInRegion(
	var/list/map,
	var/x,
	var/y,
	var/width,
	var/height,
	var/old_tile,
	var/new_tile
)
	if(!map)
		return 0

	if(width <= 0 || height <= 0)
		return 0

	var/replaced = 0

	var/right = x + width - 1
	var/top = y + height - 1

	for(var/draw_x = x, draw_x <= right, draw_x++)
		for(var/draw_y = y, draw_y <= top, draw_y++)

			if(!MapInBounds(draw_x, draw_y))
				continue

			if(MapGet(map, draw_x, draw_y) != old_tile)
				continue

			MapSet(
				map,
				draw_x,
				draw_y,
				new_tile
			)

			replaced++

	return replaced

// ============================================================
// GET MAP BOUNDS
// ============================================================
//
// Finds the minimum and maximum coordinates currently present
// in a sparse generated map.
//
// Returns:
//
//     list(
//         "min_x" = ...,
//         "max_x" = ...,
//         "min_y" = ...,
//         "max_y" = ...,
//         "width" = ...,
//         "height" = ...
//     )
//
// Returns null if the map is empty.
//
// ============================================================

world/proc/GetMapBounds(
	var/list/map
)
	if(!map || map.len <= 0)
		return null

	var/min_x = null
	var/max_x = null
	var/min_y = null
	var/max_y = null

	for(var/key in map)

		var/list/coords = splittext(key, ",")

		if(!coords || coords.len < 2)
			continue

		var/x = text2num(coords[1])
		var/y = text2num(coords[2])

		if(isnull(min_x) || x < min_x)
			min_x = x

		if(isnull(max_x) || x > max_x)
			max_x = x

		if(isnull(min_y) || y < min_y)
			min_y = y

		if(isnull(max_y) || y > max_y)
			max_y = y

	if(isnull(min_x))
		return null

	return list(
		"min_x" = min_x,
		"max_x" = max_x,
		"min_y" = min_y,
		"max_y" = max_y,
		"width" = (max_x - min_x) + 1,
		"height" = (max_y - min_y) + 1
	)

// ============================================================
// ROTATE MAP
// ============================================================
//
// Rotates a sparse generated map clockwise.
//
// rotation may be:
//
//     0
//     90
//     180
//     270
//
// The returned map is normalized so its minimum coordinate
// begins at (1,1), regardless of the original map bounds.
//
// TILE_EMPTY values are skipped.
//
// Returns a new map and does not modify the source map.
//
// ============================================================

world/proc/RotateMap(var/list/map, var/rotation)
	if(!map)
		return list()

	var/list/bounds = GetMapBounds(map)

	if(!bounds)
		return list()

	// Normalize rotation.
	rotation %= 360

	if(rotation < 0)
		rotation += 360

	if(rotation != 0 && rotation != 90 && rotation != 180 && rotation != 270)
		return list()

	var/min_x = bounds["min_x"]
	//var/max_x = bounds["max_x"]
	var/min_y = bounds["min_y"]
	//var/max_y = bounds["max_y"]

	var/width = bounds["width"]
	var/height = bounds["height"]

	var/list/result = list()

	for(var/key in map)

		var/tile = map[key]

		if(tile == TILE_EMPTY)
			continue

		var/list/coords = splittext(key, ",")

		if(!coords || coords.len < 2)
			continue

		var/x = text2num(coords[1])
		var/y = text2num(coords[2])

		// Convert to local coordinates starting at 1,1.
		var/local_x = (x - min_x) + 1
		var/local_y = (y - min_y) + 1

		var/new_x
		var/new_y

		switch(rotation)

			if(0)
				new_x = local_x
				new_y = local_y

			if(90)
				new_x = height - local_y + 1
				new_y = local_x

			if(180)
				new_x = width - local_x + 1
				new_y = height - local_y + 1

			if(270)
				new_x = local_y
				new_y = width - local_x + 1

		MapSet(
			result,
			new_x,
			new_y,
			tile
		)

	return result

// ============================================================
// FLIP MAP HORIZONTAL
// ============================================================
//
// Mirrors a sparse generated map left-to-right.
//
// The returned map is normalized to begin at (1,1).
//
// TILE_EMPTY values are skipped.
//
// Returns a new map and does not modify the source map.
//
// ============================================================

world/proc/FlipMapHorizontal(var/list/map)
	if(!map)
		return list()

	var/list/bounds = GetMapBounds(map)

	if(!bounds)
		return list()

	var/min_x = bounds["min_x"]
	var/min_y = bounds["min_y"]
	var/width = bounds["width"]

	var/list/result = list()

	for(var/key in map)

		var/tile = map[key]

		if(tile == TILE_EMPTY)
			continue

		var/list/coords = splittext(key, ",")

		if(!coords || coords.len < 2)
			continue

		var/x = text2num(coords[1])
		var/y = text2num(coords[2])

		var/local_x = (x - min_x) + 1
		var/local_y = (y - min_y) + 1

		var/new_x = width - local_x + 1
		var/new_y = local_y

		MapSet(
			result,
			new_x,
			new_y,
			tile
		)

	return result


// ============================================================
// FLIP MAP VERTICAL
// ============================================================
//
// Mirrors a sparse generated map top-to-bottom.
//
// The returned map is normalized to begin at (1,1).
//
// TILE_EMPTY values are skipped.
//
// Returns a new map and does not modify the source map.
//
// ============================================================

world/proc/FlipMapVertical(
	var/list/map
)
	if(!map)
		return list()

	var/list/bounds = GetMapBounds(map)

	if(!bounds)
		return list()

	var/min_x = bounds["min_x"]
	var/min_y = bounds["min_y"]
	var/height = bounds["height"]

	var/list/result = list()

	for(var/key in map)

		var/tile = map[key]

		if(tile == TILE_EMPTY)
			continue

		var/list/coords = splittext(key, ",")

		if(!coords || coords.len < 2)
			continue

		var/x = text2num(coords[1])
		var/y = text2num(coords[2])

		var/local_x = (x - min_x) + 1
		var/local_y = (y - min_y) + 1

		var/new_x = local_x
		var/new_y = height - local_y + 1

		MapSet(
			result,
			new_x,
			new_y,
			tile
		)

	return result
