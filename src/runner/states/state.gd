extends Node2D
class_name RunnerState

var runner
var buffer: InputBuffer
# var game: Game

var time: float = 0.0
var tick: int = 0

func init(runner_):
    self.runner = runner_
    self.buffer = runner.buffer
    # self.game = $"/root/World" as Game
    on_init()

# Set the state of the handle
func set_state(state_name):
    if runner and state_name in runner.states:
        var old_state_name = runner.state_name
        var new_state = runner.states[state_name]
        if new_state.can_start():
            on_end()
            runner.state_name = state_name
            runner.state.time = 0.0
            runner.state.tick = 0
            runner.state.on_start(old_state_name)
            #print("state: %s -> %s" % [old_state_name, state_name])

# Return true if the runner's current state is this state.
func is_active():
    return runner.state == self

# Sets the state to a "default" state.
func reset_state():
    if runner.is_on_floor():
        var axis = buffer.get_action_axis()
        if round(axis.x) != 0:
            set_state("running")
        else:
            set_state("idle")
        # set_state("idle")
    else:
        set_state("airborne")

# INPUTS
#=======================================


func process(delta):

    if runner == null:
        return

    if runner.airdashes_left > 0 and buffer.is_action_just_pressed("key_dodge", 0.4):
        set_state("airdash")
        return

    if buffer.is_action_just_pressed("shoot"):
        set_state("shootcoin")
        return

    if buffer.is_action_just_pressed("grapple"):
        if runner.lastcoin:
            set_state("grapple")
        elif runner.state_name != "attack":
            set_state("attack")
        return

    if runner.state == self:
        on_update(delta)
        tick += 1
        time += delta

# COMMON CHECKS
#===============================================================================


# Check if the player wants to drop-down a platform.
func check_dropdown_platforms():
    if runner.is_on_floor() and buffer.is_action_just_pressed("key_down"):
        runner.position += Vector2(0, 2)

# Check if the player wants to do a grounded jump.
func check_ground_jump():
    if runner.is_on_floor() and buffer.is_action_just_pressed("key_jump", 0.2):
        set_state("jumpsquat")

# Check if the player wants to do an air jump.
func check_air_jump():
    if !runner.is_on_floor() and buffer.is_action_just_pressed("key_jump", 0.2):
        runner.jump()

# Check if the player wants to fastfall.
func check_fastfall():
    if buffer.is_action_just_pressed("key_down") and runner.velocity.y > 0:
        runner.velocity.y = runner.FAST_FALL_SPEED
    
# Check if the player wants to dash.
# sensitivity: sets how hard you need to press the direction
#              for it to register (lower = more sensitive)
# require_neutral: if true, ignore dash inputs that don't go
#                  through the center of the movement axis
func check_dash(sensitivity = 0.0, require_neutral = false):
    var other_inputs = []
    if require_neutral:
        other_inputs = ["key_up", "key_down"]

    if (
        buffer.is_axis_just_pressed("key_right", "key_left", other_inputs, 0.0, sensitivity)
        or buffer.is_axis_just_pressed("key_left", "key_right", other_inputs, 0.0, sensitivity)
    ):
        set_state("dash")

# Check if player is trying to not move (no movement input)
func check_idling():
    var axis = buffer.get_action_axis()
    if axis.length() <= 0.01:
        set_state("idle")

# Check if the player is now airborne.
func check_airborne():
    if not runner.is_on_floor():
        set_state("airborne")

# Update the runner's facing direction based on movement direction.
func update_facing():
    var x = buffer.get_action_axis().x
    if x > 0:
        runner.facing = Direction.RIGHT
    elif x < 0:
        runner.facing = Direction.LEFT

# Process gravity for a frame.
func process_gravity(delta):
    runner.apply_gravity(delta)

# Process airborne acceleration (drifting) for a frame.
func process_ground_acceleration(delta):
    var x = buffer.get_action_axis().x
    runner.apply_acceleration(delta, x, runner.ACCELERATION, runner.MAX_SPEED)

# Process grounded acceleration (running) for a frame.
func process_air_acceleration(delta):
    var x = buffer.get_action_axis().x
    runner.apply_acceleration(delta, x, runner.AIR_ACCELERATION, runner.AIR_MAX_SPEED)

# Process friction for a frame.
func process_friction(delta):
    runner.apply_friction(delta, runner.FRICTION)

func process_air_friction(delta):
    var x = buffer.get_action_axis().x
    if x == 0:
        runner.apply_friction(delta, runner.AIR_FRICTION)



# called when this state is instantiated
func on_init():
    pass

# checks if the runner can enter this state
func can_start():
    return true

# called at the beginning of the state
func on_start(state_name):
    pass

# called every physics process
func on_update(_delta: float):
    pass

# called at the end of the state
func on_end():
    pass

