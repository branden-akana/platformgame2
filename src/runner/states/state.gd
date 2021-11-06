class_name RunnerState

var runner
var input: BufferedInput

# var game: Game

var time: float = 0.0
var tick: int = 0

func init(runner_):
    self.runner = runner_
    self.input = runner.input
    # self.game = $"/root/World" as Game
    on_init()

# Set the state of the handle
func set_state(state_name):
    if runner and state_name in runner.states:
        var old_state_name = runner.state_name
        var new_state = runner.states[state_name]
        if new_state.can_start():
            # Call on_end() of previous state
            on_end()
            runner.state_name = state_name
            runner.state.time = 0.0
            runner.state.tick = 0
            # Call on_start() of new state
            runner.state.on_start(old_state_name)
            # print("state: %s -> %s" % [old_state_name, state_name])

# Return true if the runner's current state is this state.
func is_active():
    return runner.state == self

# INPUTS
#=======================================


func process(delta):

    if runner == null:
        return

    if runner.airdashes_left > 0 and input.is_action_just_pressed("key_dodge", runner.BUFFER_AIRDASH):
        set_state("airdash")
        return

    if input.is_action_just_pressed("shoot"):
        set_state("shootcoin")
        return

    if input.is_action_just_pressed("grapple"):
        if runner.lastcoin:
            set_state("grapple")
        elif not runner.state_name in ["attack", "special"]:
            set_state("attack")
        return

    if input.is_action_just_pressed("special"):
        if not runner.state_name in ["attack", "special"]:
            set_state("special")

    if runner.state == self:
        on_update(delta)
        tick += 1
        time += delta

# COMMON CHECKS
#===============================================================================

# Set the runner state to either idle, running, dash, or airborne
# depending on the current state of the runner.
func goto_idle_or_dash():
    if runner.is_on_floor():
        if round(input.get_axis().x) == 0:
            set_state("idle")
        elif is_facing_forward():
            set_state("running")
        else:
            set_state("dash")
    else:
        set_state("airborne")

# Set the runner state to either idle, running, or airborne.
func goto_idle_or_run():
    if runner.is_on_floor():
        if round(input.get_axis().x) == 0:
            set_state("idle")
        else:
            set_state("running")
    else:
        set_state("airborne")

# Check if the player wants to drop-down a platform.
func check_dropdown_platforms():
    if runner.is_on_floor() and input.is_action_just_pressed("key_down"):
        runner.position += Vector2(0, 4)

# Check if the player wants to do a grounded jump.
func check_ground_jump():
    if runner.is_on_floor() and input.is_action_just_pressed("key_jump", runner.BUFFER_JUMP):
        set_state("jumpsquat")

# Check if the player wants to do an air jump.
func check_air_jump(force = false):
    if (!runner.is_on_floor() or force) and input.is_action_just_pressed("key_jump", runner.BUFFER_JUMP):
        runner.jump()

# Check if the player wants to do a jump (air or grounded).
func check_jump():
    if input.is_action_just_pressed("key_jump", runner.BUFFER_JUMP):
        if runner.is_on_floor():
            set_state("jumpsquat")
        else:
            runner.jump()

# Check if the player wants to do a walljump.
func check_wall_jump():

    var space = runner.get_world_2d().direct_space_state
    var margin = 20
    var jump_mult = 0.8
    var offset = Vector2(0, 32)

    # raycast left
    var left_result = space.intersect_ray(
        runner.position + offset,
        runner.position + offset + (Vector2.LEFT * margin),
        [], 0b0001)
    # print("left ray: %s" % left_result)
    if left_result and input.is_action_just_pressed("key_right"):
        runner.jump(jump_mult, true, runner.MAX_SPEED)
        update_facing()
        runner.emit_signal("walljump_right")

    var right_result = space.intersect_ray(
        runner.position + offset,
        runner.position + offset + (Vector2.RIGHT * margin),
        [], 0b0001)
    # print("right ray: %s" % right_result)
    if right_result and input.is_action_just_pressed("key_left"):
        runner.jump(jump_mult, true, -runner.MAX_SPEED)
        update_facing()
        runner.emit_signal("walljump_left")

# Check if the player wants to fastfall.
func check_fastfall():
    if input.is_action_just_pressed("key_down") and runner.velocity.y > 0:
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
        input.is_axis_just_pressed("key_right", "key_left", other_inputs, 0.0, sensitivity)
        or input.is_axis_just_pressed("key_left", "key_right", other_inputs, 0.0, sensitivity)
    ):
        set_state("dash")

# Check if player is trying to not move (no movement input)
func check_idling():
    var axis = input.get_axis()
    if axis.length() <= 0.01:
        set_state("idle")

# Check if the player is now airborne.
func check_airborne():
    if not runner.is_on_floor():
        set_state("airborne")

# Update the runner's facing direction based on movement direction.
func update_facing():
    var x = input.get_axis().x
    if x > 0:
        runner.facing = Direction.RIGHT
    elif x < 0:
        runner.facing = Direction.LEFT

# True if the runner is moving opposite of their facing direction.
func is_facing_forward():
    var x = input.get_axis().x
    if (
        x > 0 and runner.facing == Direction.RIGHT or
        x < 0 and runner.facing == Direction.LEFT
    ):
        return true
    return false

# Process gravity for a frame.
func process_gravity(delta):
    runner.apply_gravity(delta)

func process_acceleration(delta, accel, max_speed):
    var x = input.get_axis().x
    runner.apply_acceleration(delta, x, accel, max_speed)

# Process airborne acceleration (drifting) for a frame.
func process_ground_acceleration(delta):
    process_acceleration(delta, runner.ACCELERATION, runner.MAX_SPEED)

# Process grounded acceleration (running) for a frame.
func process_air_acceleration(delta):
    process_acceleration(delta, runner.AIR_ACCELERATION, runner.AIR_MAX_SPEED)

# Process friction for a frame.
func process_friction(delta):
    runner.apply_friction(delta, runner.FRICTION)

func process_air_friction(delta):
    var x = input.get_axis().x
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

