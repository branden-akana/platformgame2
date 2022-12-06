# Provides an interface to process inputs with a buffer.
# Time is measured in ticks for precision.
#
class_name BufferedInput

# threshold to trigger a "press" for analog inputs
const PRESS_THRESHOLD = 0.5

# map of input values
var action_map: Dictionary = {}

# map of input deltas (difference in input value after a press, used for analog inputs)
var action_deltas: Dictionary = {}

# map of when inputs were pressed
var action_press_times: Dictionary = {}

# map of when inputs were unpressed
var action_unpress_times: Dictionary = {}

# map of when inputs were pressed, but
# unpressing will remove_at them from this map
var action_holds: Dictionary = {}

# the user's current joystick direction
var axis: Vector2 = Vector2.ZERO

# the user's joystick direction checked the last frame
var last_axis: Vector2 = axis

var tick: int = 0
var time: float = 0.0

# Clear the buffer
func reset():
	action_map = {}
	action_deltas = {}
	action_press_times = {}
	action_unpress_times = {}
	action_holds = {}

func duplicate() -> BufferedInput:
	@warning_ignore("UNSAFE_METHOD_ACCESS")
	var copy = get_script().new()
	copy.action_map = action_map.duplicate(true)
	copy.action_deltas = action_deltas.duplicate(true)
	copy.action_press_times = action_press_times.duplicate(true)
	copy.action_unpress_times = action_unpress_times.duplicate(true)
	copy.action_holds = action_holds.duplicate(true)
	return copy

##
## Increments tick counter and updates internal variables.
##
func update():
	tick += 1
	time += 1.0 / 60.0
	last_axis = axis
	axis = get_axis()
	# print(axis)

## Return the difference between the current time and the given time.
##
func get_delta_time(test_tick: int) -> int:
	# return (get_current_time() - time) / 1000.0
	return self.tick - test_tick

## Manually trigger a press for this input. This input will be stored in the buffer map
## along with the time it was pressed.
##
func update_action(input: String, value: float = 1.0) -> void:
	var input_delta
	var past_value
	if not input in action_map:
		past_value = 0
		input_delta = value
	else:
		past_value = action_map[input]
		input_delta = value - past_value

	action_deltas[input] = input_delta

	# detect press
	if past_value < PRESS_THRESHOLD and value >= PRESS_THRESHOLD:
		# print("read press (%s) delta: %.2f" % [input, input_delta])
		action_press_times[input] = tick
		action_holds[input] = tick

	# detect unpress
	elif past_value >= PRESS_THRESHOLD and value < PRESS_THRESHOLD:
		action_unpress_times[input] = tick
		action_holds.erase(input)

	# update values
	action_map[input] = value

# Get the time (in frames) from the last time this input has been pressed.
func get_time_since_last_pressed(input: String) -> int:
	if not input in action_press_times:
		return 100000
	else:
		var buffer = get_delta_time(action_press_times[input])
		return buffer 

# Get the time (in frames) from the last time this input has been unpressed.
func get_time_since_last_unpressed(input: String) -> int:
	if not input in action_unpress_times:
		return 100000
	else:
		var buffer = get_delta_time(action_unpress_times[input])
		return buffer 

# Get the time (in seconds) that this input has been held down.
func get_time_held(input: String) -> int:
	if input in action_holds:
		return get_delta_time(action_holds[input])
	return 0

##
## Read an action press with an input buffer (in seconds).
##
## For example, reading an action press with a buffer window of 4 will return true
## even if the press happened up to 4 ticks ago.
##
## If `delta` is given, the press will only register if the difference in the input strength is at least this value.
##
## If `clear` is true, the last-press time of the action will be reset when a press is detected.
## The action is considered "eaten" and any repeat calls of this function will return false (for the current physics step).
## When using this function just to check if an action press "would have" been detected, it is recommended to
## set `clear` to false.
##
func is_action_just_pressed(input, buffer_window: int = 0, delta: float = 0.0, clear = true):
	var last_pressed = get_time_since_last_pressed(input)
	var input_delta = get_action_delta(input)

	if last_pressed <= buffer_window and input_delta >= delta:
		if clear: eat_input(input)
		return true
	else:
		return false

##
## Returns true if the movement axis has just been pushed in a given direction
## past PRESS_THRESHOLD.
##
## If resistance is provided, only return true if the difference in axis movement between
## this tick and the previous tick is greater than the resistance.
## Higher resistance values will require quicker movements of the axis to register.
##
func is_axis_just_pressed(dir: Vector2, resistance := 0.4):

	var is_pressed = self.axis.dot(dir) > PRESS_THRESHOLD
	var was_pressed = self.last_axis.dot(dir) > PRESS_THRESHOLD

	if is_pressed and not was_pressed and axis.distance_to(last_axis) >= resistance:
		return true
	else:
		return false


# Reads the difference between two inputs with a buffer (in seconds).
# Movements occuring within this buffer will still count as a press.
# input: the input representing primary direction
# opposite_input: the input representing opposite direction
# other_inputs: if any of these inputs are also pressed, ignore the primary press
func _is_axis_just_pressed(input: String, opposite_input: String, other_inputs = [], tolerance: int = 0, delta: float = 0.0):

	var a_last_pressed = get_time_since_last_pressed(input)
	var a_is_pressed = is_action_pressed(input)
	var a_delta = get_action_delta(input)
	var b_last_unpressed = get_time_since_last_unpressed(opposite_input)
	var b_is_pressed = is_action_pressed(opposite_input)

	var press_detected = false

	# print("press time: %s, opp unpress time: %s" % [a_last_pressed, b_last_unpressed])

	# detect a press if:
	# (1) the primary input has just been pressed and the opposite input is not held or
	# (2) the opposite input has just been unpressed and the primary input is held

	# no buffer case
	if tolerance == 0:
		press_detected = is_action_just_pressed(input)

	# buffer case
	else:
		press_detected = (
			(a_last_pressed <= tolerance and a_delta >= delta and !b_is_pressed)
			or (b_last_unpressed <= tolerance and a_is_pressed)
		)

	if press_detected:
		# check if any of the other inputs are pressed
		for inp in other_inputs:
			if is_action_pressed(inp):
				return false
		return true

	return false

# Create an axis (Vector2) given the prefix of the action.
# This assumes the directional actions are -"right", -"left", -"up", -"down"
func get_axis(prefix="key_") -> Vector2:
	var right = prefix + "right"
	var left  = prefix + "left"
	var up    = prefix + "up"
	var down  = prefix + "down"
	var axis = Vector2(
		get_action_strength(right) - get_action_strength(left),
		get_action_strength(down) - get_action_strength(up)
	)
	return axis.limit_length()

func is_action_pressed(input: String) -> bool:
	if input in action_map:
		return action_map[input] >= PRESS_THRESHOLD
	else:
		return false

func get_action_strength(input: String) -> float:
	if input in action_map:
		return action_map[input]
	else:
		return 0.0

func get_action_delta(input: String) -> float:
	if input in action_deltas:
		return action_deltas[input]
	else:
		return 0.0
	
func eat_input(input: String) -> void:
	action_press_times.erase(input)
