#================================================================================
# Runner State
#
# Represents a state a runner can be in.
#
# on_start(state_from)
# Called when the runner enters this state, given the runner's previous state.
#
# on_update()
# Called every tick while the runner is in this state.
#
# on_end()
# Called when the runner leaves this state.
#================================================================================
class_name RunnerState

var time: float = 0.0  # the amount of time (in seconds) the runner has been in this state
var tick: int = 0      # the amount of time (in ticks) the runner has been in this state

func is_current_state(fsm):
    return fsm.current_state == self

# INPUTS
#=======================================
# Called every tick (by the runner's _physics_process() loop).
# Will only be called while the runner is in this state.
func process(delta, runner, fsm):

    # THE BELOW CHECKS WILL APPLY TO ALL STATES
    #------------------------------------------

    var current_type = fsm.current_type

    # allow airdash
    if runner.airdashes_left > 0 and runner.pressed_airdash():
        var axis = runner.get_axis()
        if (
            not axis.is_equal_approx(Vector2.ZERO)
            and current_type == State.ATTACK
            and not runner.is_grounded() or current_type != State.ATTACK
            and round(axis.length()) != 0
        ):
            print("initiated airdash")
            fsm.goto_airdash()
            return

    # allow attack
    if runner.pressed_attack():
        if not current_type in [State.ATTACK, State.SPECIAL]:
            runner.do_attack()
        return

    # allow special attack
    if runner.pressed_special():
        if not current_type in [State.ATTACK, State.SPECIAL]:
            fsm.goto_special()

    # update current state
    if fsm.current_state == self:
        on_update(delta, runner, fsm)
        tick += 1
        time += delta


# COMMON CHECKS
#===============================================================================


# Check if the player wants to drop-down a platform.
func allow_dropdown(runner):
    if runner.pressed_down():
        runner.do_dropdown()


# Check if the player wants to do a jump (air or grounded).
func allow_jump_out(runner):
    if runner.pressed_jump():
        runner.do_jump()


# Check if the player wants to do a walljump.
func allow_walljump(runner):

    if runner.WALLJUMP_TYPE == runner.WalljumpType.JOYSTICK:

        if runner.pressed_right():
            runner.action_walljump_right()
            
        if runner.pressed_left():
            runner.action_walljump_left()
    
    elif runner.WALLJUMP_TYPE == runner.WalljumpType.JUMP:

        if runner.pressed_jump_raw():
            runner.action_walljump_any()


# Check if the player wants to fastfall.
func allow_fastfall(runner):
    if runner.pressed_down() and runner.velocity.y > 0:
        runner.velocity.y = runner.FAST_FALL_SPEED


# Switch player to the airborne state if not grounded.
func allow_air_out(runner):
    if not runner.is_grounded(): runner.fsm.goto_airborne()


# Switch player to any grounded state if grounded.
func allow_land_out(runner):
    if runner.is_grounded(): runner.fsm.goto_grounded()
    

# Check if the player wants to dash.
# sensitivity: sets how hard you need to press the direction
#              for it to register (lower = more sensitive)
# require_neutral: if true, ignore dash inputs that don't go
#                  through the center of the movement axis
func allow_dash_out(runner):
    # if (
    #     runner.pressed_left_thru_neutral()
    #     or runner.pressed_right_thru_neutral()
    # ):
    if (runner.pressed_left() or runner.pressed_right()):
        runner.fsm.goto_dash()

# Check if player is trying to not move (no movement input)
func allow_idle_out(runner):
    if runner.is_axis_neutral():
        runner.fsm.goto_idle()

func process_acceleration(runner, delta, accel, max_speed):
    runner.apply_acceleration(delta, runner.get_axis_x(), accel, max_speed)

# Process airborne acceleration (drifting) for a frame.
func process_ground_acceleration(runner, delta):
    process_acceleration(runner, delta, runner.ACCELERATION, runner.MAX_SPEED)

# Process grounded acceleration (running) for a frame.
func process_air_acceleration(runner, delta):
    process_acceleration(runner, delta, runner.AIR_ACCELERATION, runner.AIR_MAX_SPEED)

# Process friction for a frame.
func process_friction(runner, delta):
    runner.apply_friction(delta, runner.FRICTION)

func process_air_friction(runner, delta):
    if runner.is_axis_x_neutral():
        runner.apply_friction(delta, runner.AIR_FRICTION)

# called when this state is instantiated
func on_init(runner):
    pass

# checks if the runner can enter this state
func can_start(runner):
    return true

# called at the beginning of the state
func on_start(state_from, runner, fsm):
    pass

# called every physics process
func on_update(delta: float, runner, fsm):
    pass

# called at the end of the state
func on_end(state_to, runner, fsm):
    pass

