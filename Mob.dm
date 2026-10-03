// ============================================================
// PLAYER MOVEMENT CONTROL
// ============================================================

mob
	var/can_move = TRUE


	// ========================================================
	// MOVEMENT
	// ========================================================
	//
	// Prevent movement while can_move is FALSE.
	//
	// Anything that attempts to move the mob through Move()
	// will be blocked until movement is enabled again.
	//
	// ========================================================

	Move(NewLoc, Dir = 0, step_x = 0, step_y = 0)

		if(!can_move)
			return FALSE

		return ..()

mob/proc/FreezeMovement() can_move = FALSE
mob/proc/UnfreezeMovement() can_move = TRUE