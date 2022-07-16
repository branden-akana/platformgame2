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

var b_can_airdash_cancel = false
var b_can_attack_cancel = false
var b_can_special_cancel = false

var b_can_dash_cancel = false
var b_can_jump_cancel = false
var b_can_walljump_cancel = false
var b_can_edge_cancel = false
var b_can_air_cancel = false
var b_can_land_cancel = false
var b_can_idle_cancel = false

var b_can_dropdown = false
var b_can_fastfall = false  # ?

func is_current_state(fsm):
    return fsm._current_state() == self

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

# Called every physics process.
#
# If this function returns a RunnerStateType, this state is considered
# finished and the player should transition to that state.
func on_update(delta: float, runner, fsm):
    return null

# called at the end of the state
func on_end(state_to, runner, fsm):
    pass

# Allow leaving this state by dashing.
func allow_dash_cancel() -> void: b_can_dash_cancel = true

# Allow leaving this state by airdashing.
func allow_airdash_cancel() -> void: b_can_airdash_cancel = true

# Allow leaving this state by jumping.
func allow_jump_cancel() -> void: b_can_jump_cancel = true

# Allow leaving this state by walljumping.
func allow_walljump_cancel() -> void: b_can_walljump_cancel = true

# Allow leaving this state by leaving the ground after
# touching the ground at any point.
func allow_edge_cancel() -> void: b_can_edge_cancel = true

# Allow leaving this state by being off the ground.
func allow_air_cancel() -> void: b_can_air_cancel = true

# Allow leaving this state by landing on the ground.
func allow_land_cancel() -> void: b_can_land_cancel = true

# Allow leaving this state by not moving.
func allow_idle_cancel() -> void: b_can_idle_cancel = true

# Allow leaving this state by attacking (normal).
func allow_attack_cancel() -> void: b_can_attack_cancel = true

# Allow leaving this state by attacking (normal).
func allow_special_cancel() -> void: b_can_special_cancel = true


# Allow the action of dropping down platforms.
# This may cause the state to end early.
func allow_dropdown() -> void: b_can_dropdown = true

# Allow the action of fastfalling.
func allow_fastfall() -> void: b_can_fastfall = true
