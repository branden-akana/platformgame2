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
            print("state: %s -> %s" % [old_state_name, state_name])

# Return true if the runner's current state is this state.
func is_active():
    return runner.state == self

# INPUTS
#=======================================
func process(delta):

    if runner == null:
        return

    update_grounded()

    # THE BELOW CHECKS WILL APPLY TO ALL STATES
    #------------------------------------------

    # allow airdash
    if runner.airdashes_left > 0 and input.is_action_just_pressed("key_dodge", runner.BUFFER_AIRDASH):
        if runner.state_name == "attack" and not runner.is_grounded() or runner.state_name != "attack":
            print("initiated airdash")
            goto_airdash()
            return

    # shoot projectile (unused)
    if input.is_action_just_pressed("shoot"):
        set_state("shootcoin")
        return

    # allow attack
    if input.is_action_just_pressed("grapple"):
        if runner.lastcoin:
            set_state("grapple")
        elif not runner.state_name in ["attack", "special"]:
            goto_attack()
        return

    # allow special attack
    if input.is_action_just_pressed("special"):
        if not runner.state_name in ["attack", "special"]:
            goto_special()

    # update current state
    if runner.state == self:
        on_update(delta)
        tick += 1
        time += delta

# State Changers
#================================================================================

func goto_idle():      set_state("idle")
func goto_running():   set_state("running")
func goto_dash():      set_state("dash")

func goto_jumpsquat(): set_state("jumpsquat")
func goto_airborne():  set_state("airborne")

func goto_airdash():   set_state("airdash")

func goto_attack():    set_state("attack")
func goto_special():   set_state("special")
        
# Set the runner state to either idle, running, dash, or airborne
# depending on the current state of the runner.
func goto_idle_or_dash():
    if runner.is_on_floor():
        if round(input.get_axis().x) == 0:
            goto_idle()
        elif is_facing_forward():
            goto_running()
        else:
            goto_dash()
    else:
        goto_airborne()

# Set the runner state to either idle, running, or airborne.
func goto_idle_or_run():
    if runner.is_on_floor():
        if round(input.get_axis().x) == 0:
            goto_idle()
        else:
            goto_running()
    else:
        goto_airborne()

# COMMON CHECKS
#===============================================================================

# Snap to platforms, forcing a grounded state when 
# airdashing slightly under them by a set margin.
func snap_up_to_ground(delta, margin = runner.AIRDASH_WAVELAND_MARGIN, goto_state=null):
    var ray_length = margin
    if runner.is_grounded(): ray_length = 2

    var ray = Util.intersect_ray(runner, Vector2(0, 32 - margin), Vector2.DOWN * ray_length)
    if runner.velocity.y >= 0 and ray:
        # print("detected below floor")
        runner.move_and_collide(Vector2.UP * margin * 2)
        runner.move_and_slide(Vector2.DOWN * margin * 2 / delta, Vector2.UP)
        if runner.is_on_floor():
            runner.set_grounded(true, false)
            if goto_state and goto_state != runner.state_name:
                set_state(goto_state)
            return true
    return false

func snap_down_to_ground(delta, margin = runner.FLOOR_SNAP_TOP_MARGIN, goto_state = null):
    var ray = Util.intersect_ray(runner, Vector2(0, 32 + margin), Vector2.DOWN)
    if runner.velocity.y >= 0 and ray and not runner.is_grounded():
        runner.move_and_slide(Vector2.DOWN * margin * 2 / delta, Vector2.UP)
        if runner.is_on_floor():
            # print("floor snap down")
            runner.set_grounded(true, false)
            if goto_state and goto_state != runner.state_name:
                set_state(goto_state)
            return true
    return false

# Check if the player wants to drop-down a platform.
func dropdown_platforms_if_able():
    if runner.is_on_floor() and input.is_action_just_pressed("key_down"):
        # check if the tile is a drop-down
        if not Util.collide_point(runner, runner.position + Vector2(0, 96)):
            runner.position += Vector2(0, 4)
            goto_airborne()

# Check if the player wants to do a grounded jump.
func ground_jump_if_able():
    if runner.is_on_floor() and input.is_action_just_pressed("key_jump", runner.BUFFER_JUMP):
        goto_jumpsquat()

# Check if the player wants to do an air jump.
func air_jump_if_able(force = false):
    if (!runner.is_on_floor() or force) and input.is_action_just_pressed("key_jump", runner.BUFFER_JUMP):
        runner.jump()

# Check if the player wants to do a jump (air or grounded).
func jump_if_able():
    if input.is_action_just_pressed("key_jump", runner.BUFFER_JUMP):
        if runner.is_on_floor():
            goto_jumpsquat()
        else:
            runner.jump()

# Check if the player wants to do a walljump.
func walljump_if_able():

    var margin = 30
    var jump_mult = 0.8
    var top_offset = Vector2(0, 0)
    var bot_offset = Vector2(0, 32)
    var left = Vector2.LEFT * margin
    var right = Vector2.RIGHT * margin

    # raycast left (top and bottom rays)
    var left_1 = Util.intersect_ray(runner, top_offset, left)
    var left_2 = Util.intersect_ray(runner, bot_offset, left)
    # print("left ray: %s" % left_result)

    if left_1 and left_2 and input.is_action_just_pressed("key_right"):
        runner.jump(jump_mult, true, runner.MAX_SPEED)
        update_facing()
        runner.emit_signal("walljump_right")

    # raycast right (top and bottom rays)
    var right_1 = Util.intersect_ray(runner, top_offset, right)
    var right_2 = Util.intersect_ray(runner, bot_offset, right)
    # print("right ray: %s" % right_result)

    if right_1 and right_2 and input.is_action_just_pressed("key_left"):
        runner.jump(jump_mult, true, -runner.MAX_SPEED)
        update_facing()
        runner.emit_signal("walljump_left")

# Check if the player wants to fastfall.
func fastfall_if_able():
    if input.is_action_just_pressed("key_down", 10) and runner.velocity.y > 0:
        runner.velocity.y = runner.FAST_FALL_SPEED
    
# Check if the player wants to dash.
# sensitivity: sets how hard you need to press the direction
#              for it to register (lower = more sensitive)
# require_neutral: if true, ignore dash inputs that don't go
#                  through the center of the movement axis
func dash_if_able(sensitivity = 0.0, require_neutral = false):
    var other_inputs = []
    if require_neutral:
        other_inputs = ["key_up", "key_down"]

    if (
        input.is_axis_just_pressed("key_right", "key_left", other_inputs, 0.0, sensitivity)
        or input.is_axis_just_pressed("key_left", "key_right", other_inputs, 0.0, sensitivity)
    ):
        goto_dash()

# Check if player is trying to not move (no movement input)
func idle_if_idling():
    var axis = input.get_axis()
    if axis.length() <= 0.01:
        goto_idle()

# Check if the player is now airborne.
func goto_airborne_if_not_grounded():
    if not runner.is_grounded():
        goto_airborne()

func update_grounded():
    if not runner.is_grounded() and runner.is_on_floor():
        runner.set_grounded(true)
    elif runner.is_grounded() and not runner.is_on_floor():
        runner.set_grounded(false)

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

