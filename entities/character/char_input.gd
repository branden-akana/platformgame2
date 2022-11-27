class_name CharacterInput extends BufferedInput

var character

func _init(character):
	self.character = character

func duplicate() -> BufferedInput:
	@warning_ignore("UNSAFE_METHOD_ACCESS")
	var copy = get_script().new(character)
	copy.action_map = action_map.duplicate(true)
	copy.action_deltas = action_deltas.duplicate(true)
	copy.action_press_times = action_press_times.duplicate(true)
	copy.action_unpress_times = action_unpress_times.duplicate(true)
	copy.action_holds = action_holds.duplicate(true)
	return copy

func pressed_down() -> bool:
	return is_action_just_pressed("key_down")

func pressed_up() -> bool:
	return is_action_just_pressed("key_up")

func pressed_left() -> bool:
	# return is_action_just_pressed("key_left")
	return is_axis_just_pressed(Vector2.LEFT)

func pressed_right() -> bool:
	return is_axis_just_pressed(Vector2.RIGHT)
	# return is_action_just_pressed("key_right")

func holding_down() -> bool:
	return is_action_pressed("key_down")

func holding_up() -> bool:
	return is_action_pressed("key_up")

func holding_left() -> bool:
	return is_action_pressed("key_left")

func holding_right() -> bool:
	return is_action_pressed("key_right")

func get_axis_rounded() -> Vector2:
	var axis = get_axis()

	if axis.x >= 0.5:
		axis.x = 1
	elif axis.x <= -0.5:
		axis.x = -1

	if axis.y >= 0.5:
		axis.y = 1
	elif axis.y <= -0.5:
		axis.y = -1

	return axis

# Read for a left input, but only if up or down are not pressed.
func pressed_left_thru_neutral():
	pass
	# return _is_axis_just_pressed(Vector2.LEFT, Vector2.ZERO)
	# return is_axis_just_pressed(
	# 	"key_right", "key_left", ["key_up", "key_down"], 0, 0.0
	# )

# Read for a right input, but only if up or down are not pressed.
func pressed_right_thru_neutral():
	pass
	# return _is_axis_just_pressed(Vector2.RIGHT, Vector2.ZERO)
	# return is_axis_just_pressed(
	# 	"key_left", "key_right", ["key_up", "key_down"], 0, 0.0
	# )

# Return true if the left stick is in the neutral position.
func is_axis_neutral():
	var deadzone = 0.01
	return get_axis().length() <= deadzone

func is_axis_x_neutral():
	var deadzone = 0.01
	return abs(get_axis().x) <= deadzone

func get_axis_x() -> float:
	return get_axis().x

func pressed_jump():
	return is_action_just_pressed("jump", character._phys.BUFFER_JUMP, 0.0, false)

func pressed_jump_raw():
	return is_action_just_pressed("jump")

func holding_jump():
	return is_action_pressed("jump")

func pressed_attack():
	return is_action_just_pressed("attack")

func pressed_special():
	return is_action_just_pressed("special")

func pressed_airdash():
	return is_action_just_pressed("dodge", character._phys.BUFFER_AIRDASH)