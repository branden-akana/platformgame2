class_name InputBuffer

# threshold to trigger a "press" for analog inputs
const PRESS_THRESHOLD = 0.3

# map of input values
var input_map = {}

# map of input deltas (difference in input value after a press, used for analog inputs)
var input_deltas = {}

# map of when inputs were pressed
var input_buffer = {}

# Clear the buffer
func reset():
    input_buffer = {}
    input_map = {}
    input_deltas = {}


# Manually trigger a press for this input. This input will be stored in the buffer map
# along with the time it was pressed.
func trigger_press(input, value=1):
    var input_delta
    var past_value
    if not input in input_map:
        past_value = 0
        input_delta = value
    else:
        past_value = input_map[input]
        input_delta = value - past_value

    input_deltas[input] = input_delta

    if past_value < PRESS_THRESHOLD and value >= PRESS_THRESHOLD:
        # print("read press (%s) delta: %.2f" % [input, input_delta])
        input_buffer[input] = OS.get_ticks_msec()

    input_map[input] = value

# Get the time (in seconds) from the last time this input has been pressed.
func get_time_since_last_pressed(input):
    if not input in input_buffer:
        return INF
    else:
        var buffer = (OS.get_ticks_msec() - input_buffer[input]) / 1000.0
        return buffer 

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
                input_buffer.erase(input)
            return true
        else:
            return false

# Create an axis (Vector2) from four actions representing the directions.
func get_action_axis(right="key_right", left="key_left", up="key_up", down="key_down") -> Vector2:
    var axis = Vector2(
        get_action_strength(right) - get_action_strength(left),
        get_action_strength(down) - get_action_strength(up)
    )
    return axis

func is_action_pressed(input):
    if input in input_map:
        return input_map[input] >= PRESS_THRESHOLD
    else:
        return false

func get_action_strength(input):
    if input in input_map:
        return input_map[input]
    else:
        return 0.0

func get_action_delta(input):
    if input in input_deltas:
        return input_deltas[input]
    else:
        return 0.0
    

