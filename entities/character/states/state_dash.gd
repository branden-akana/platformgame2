class_name DashState extends CharacterState

func _init(character):
	super(character, [
		CharacterActions.AIRDASH,
		CharacterActions.ATTACK,
		CharacterActions.SPECIAL,
		CharacterActions.JUMP,
		CharacterActions.DASH,
		CharacterActions.EDGE_CANCEL,
		CharacterActions.AIR_CANCEL,
		CharacterActions.IDLE_CANCEL,
		CharacterActions.DROPDOWN,
		# CharacterActions.FASTFALL,
		# CharacterActions.LAND,
		# CharacterActions.WALLJUMP,
	])

func on_start(_state_from, _fsm):

	var axis_x = character.input.get_axis_x()

	# determine dash direction
	if axis_x > 0:
		character.facing = Direction.RIGHT
	else:
		character.facing = Direction.LEFT

	# set velocity
	if axis_x > 0:
		FXEmitter.play(FXEmitter.Dash, character, {"direction": Vector2(-3, -1)})
		character.velocity.x = character._phys.DASH_INIT_SPEED
	elif axis_x < 0:
		FXEmitter.play(FXEmitter.Dash, character, {"direction": Vector2(3, -1)})
		character.velocity.x = -character._phys.DASH_INIT_SPEED

func on_end(state_to, _fsm):

	var facing = character.facing
	var vel_x = character.velocity.x

	if state_to == CharStateName.IDLE:
		if character.facing == Direction.RIGHT and vel_x > 0:
			character.velocity.x = character._phys.DASH_STOP_SPEED
		elif character.facing == Direction.LEFT and vel_x < 0:
			character.velocity.x = -character._phys.DASH_STOP_SPEED


func on_update(delta, _fsm):

	#snap_down_to_ground(delta)
	#snap_up_to_ground(delta, 16)

	# var axis = character.input.get_axis()

	# # used to determine which way to accelerate;
	# # can only be 1 or -1 (disregard the analog part)
	# var dir

	# # if true, character is holding stick in opposite direction
	# var is_reversed = false

	# match(character.facing):
	# 	Direction.RIGHT:
	# 		if axis.x >= 0:
	# 			dir = Vector2.RIGHT
	# 		else:
	# 			is_reversed = true
	# 			dir = Vector2.LEFT

	# 	Direction.LEFT:
	# 		if axis.x <= 0:
	# 			dir = Vector2.LEFT
	# 		else:
	# 			is_reversed = true
	# 			dir = Vector2.RIGHT

	# var accel = character._phys.DASH_ACCELERATION
	# var max_speed = character._phys.DASH_MAX_SPEED

	# change acceleration if reversed (allow moonwalking)
	# if is_reversed:
	#     accel = character._phys.DASH_ACCELERATION_REV
	#     max_speed = character._phys.DASH_MAX_SPEED_REV

	# character.apply_acceleration(delta, effective_axis, accel, max_speed)
	var accel = character._phys.DASH_ACCELERATION
	var max_speed = character._phys.DASH_MAX_SPEED
	character._acceleration(delta, accel, max_speed)

	# end of dash
	if tick >= character._phys.DASH_LENGTH:
		character.action_run()
		# allow_land_cancel()
