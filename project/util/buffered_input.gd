class_name BufferedInput

# threshold to trigger a "press" for analog inputs
const PRESS_THRESHOLD = 0.5

# map of input values
var action_map = {}

# map of input deltas (difference in input value after a press, used for analog inputs)
var action_deltas = {}

# map of when inputs were pressed
var action_press_times = {}

# map of when inputs were unpressed
var action_unpress_times = {}

# map of when inputs were pressed, but
# unpressing will remove them from this map
var action_holds = {}

# Clear the buffer
func reset():
    action_map = {}
    action_deltas = {}
    action_press_times = {}
    action_unpress_times = {}
    action_holds = {}

func duplicate() -> BufferedInput:
    var copy = get_script().new()
    copy.action_map = action_map.duplicate(true)
    copy.action_deltas = action_deltas.duplicate(true)
    copy.action_press_times = action_press_times.duplicate(true)
    copy.action_unpress_times = action_unpress_times.duplicate(true)
    copy.action_holds = action_holds.duplicate(true)
    return copy

# Return the current time.
func get_current_time():
    return OS.get_ticks_msec()

# Return the difference between the current time and the given time.
func get_delta_time(time):
    return (get_current_time() - time) / 1000.0

# Manually trigger a press for this input. This input will be stored in the buffer map
# along with the time it was pressed.
func update_action(input, value=1):
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
        action_press_times[input] = get_current_time()
        action_holds[input] = get_current_time()

    # detect unpress
    elif past_value >= PRESS_THRESHOLD and value < PRESS_THRESHOLD:
        action_unpress_times[input] = get_current_time()
        action_holds.erase(input)

    # update values
    action_map[input] = value

# Get the time (in seconds) from the last time this input has been pressed.
func get_time_since_last_pressed(input):
    if not input in action_press_times:
        return INF
    else:
        var buffer = get_delta_time(action_press_times[input])
        return buffer 

# Get the time (in seconds) from the last time this input has been unpressed.
func get_time_since_last_unpressed(input):
    if not input in action_unpress_times:
        return INF
    else:
        var buffer = get_delta_time(action_unpress_times[input])
        return buffer 

# Get the time (in seconds) that this input has been held down.
func get_time_held(input):
    if input in action_holds:
        return get_delta_time(action_holds[input])
    return 0

# Read an input with a buffer (in seconds).
# For example, reading an input press with a 0.5s tolerance will return true
# even if the press happened up to 0.5s ago.
# If "delta" is given, the press will only register if the difference in the input strength is at least this value.
func is_action_just_pressed(input, tolerance: float = 0.0, delta=0.0, clear=true):
    if tolerance == 0.0:
        var last_pressed = get_time_since_last_pressed(input)
        if abs(last_pressed) < 0.01 and get_action_delta(input) >= delta:
            return true
        else:
            return false
    else:
        var last_pressed = get_time_since_last_pressed(input)
        var input_delta = get_action_delta(input)
        if last_pressed <= tolerance and input_delta >= delta:
            # print("[%s] last pressed: %.2f, delta: %.2f" % [input, last_pressed, input_delta])
            if clear:
                action_press_times.erase(input)
            return true
        else:
            return false

# Reads the difference between two inputs with a buffer (in seconds).
# Movements occuring within this buffer will still count as a press.
# input: the input representing primary direction
# opposite_input: the input representing opposite direction
# other_inputs: if any of these inputs are also pressed, ignore the primary press
func is_axis_just_pressed(input: String, opposite_input: String, other_inputs = [], tolerance: float = 0.0, delta: float = 0.0):

    var a_last_pressed = get_time_since_last_pressed(input)
    var a_is_pressed = is_action_pressed(input)
    var a_delta = get_action_delta(input)
    var b_last_unpressed = get_time_since_last_unpressed(opposite_input)
    var b_is_pressed = is_action_pressed(opposite_input)

    var press_detected = false

    # detect a press if:
    # (1) the primary input has just been pressed and the opposite input is not held or
    # (2) the opposite input has just been unpressed and the primary input is held

    # no buffer case
    if tolerance == 0.0:
        press_detected = (
            (abs(a_last_pressed) < 0.01 and a_delta >= delta and !b_is_pressed)
            or (abs(b_last_unpressed) < 0.01 and a_is_pressed)
        )

    # buffer case
    else:
        press_detected = (
            (a_last_pressed <= tolerance and a_delta >= delta and !b_is_pressed)
            or (b_last_unpressed <= tolerance and a_is_pressed)
        )

    if press_detected:
        # check if any of the other inputs are pressed
        for input in other_inputs:
            if is_action_pressed(input):
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
    return axis

func is_action_pressed(input):
    if input in action_map:
        return action_map[input] >= PRESS_THRESHOLD
    else:
        return false

func get_action_strength(input):
    if input in action_map:
        return action_map[input]
    else:
        return 0.0

func get_action_delta(input):
    if input in action_deltas:
        return action_deltas[input]
    else:
        return 0.0
    

