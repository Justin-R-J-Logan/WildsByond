/*
	These are simple defaults for your project.
 */
#define DEBUG
#define TILE_OCEAN 0
#define TILE_LAND  1

world
	fps = 60		// 60 frames per second
	icon_size = 32	// 32x32 icon size by default

	view = 32		// show up to 6 tiles outward from center (13x13 view)


// Make objects move 8 pixels per tick when walking

mob
	step_size = 32

obj
	step_size = 32

