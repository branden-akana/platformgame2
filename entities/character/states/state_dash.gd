extends CharacterState
class_name DashState

func on_start(state_from, character, fsm):

	# determine dash direction
	character.set_facing_to_input()

	# play dash sound
	character.emit_signal("dash")

	# set velocity
	match character.facing:
		Direction.RIGHT:
			Effects.play(Effects.Dash, character, {"direction": Vector2(-3, -1)})
			character.velocity.x = character.DASH_INIT_SPEED
		Direction.LEFT:
			Effects.play(Effects.Dash, character, {"direction": Vector2(3, -1)})
			character.velocity.x = -character.DASH_INIT_SPEED

func on_end(state_to, character, fsm):

	b_can_land_cancel = false

	if state_to == CharStateName.IDLE:
		if character.facing == Direction.RIGHT:
			character.velocity.x = character.DASH_STOP_SPEED
		else:
			character.velocity.x = -character.DASH_STOP_SPEED


func on_update(delta, character, fsm):

	#snap_down_to_ground(delta)
	#snap_up_to_ground(delta, 16)

	var axis = character.get_axis()

	# used to determine which way to accelerate;
	# can only be 1 or -1 (disregard the analog part)
	var dir

	# if true, character is holding stick in opposite direction
	var is_reversed = false

	match(character.facing):
		Direction.RIGHT:
			if axis.x >= 0:
				dir = Vector2.RIGHT
			else:
				is_reversed = true
				dir = Vector2.LEFT

		Direction.LEFT:
			if axis.x <= 0:
				dir = Vector2.LEFT
			else:
				is_reversed = true
				dir = Vector2.RIGHT

	# var accel = character.DASH_ACCELERATION
	# var max_speed = character.DASH_MAX_SPEED

	# change acceleration if reversed (allow moonwalking)
	# if is_reversed:
	#     accel = character.DASH_ACCELERATION_REV
	#     max_speed = character.DASH_MAX_SPEED_REV

	# character.apply_acceleration(delta, effective_axis, accel, max_speed)
	character._acceleration(delta)

	# end of dash
	if tick >= character.DASH_LENGTH:
		return CharStateName.RUNNING
		# allow_land_cancel()
