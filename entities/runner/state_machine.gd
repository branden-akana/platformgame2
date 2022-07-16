#================================================================================
# Runner State Machine
#
# A state machine for RunnerStates. A runner will contain one instance of this class.
#
# Contains an instance of every state a runner can be in.
# Methods are provided to change the runner's state, however,
# the changing of states is managed by each individual state.
#================================================================================

class_name StateMachine

signal state_changed

var states = {}

var runner

# if not null, contains the next state to transition to
# during the current physics tick.
var queued_state_type = null

var current_type: int = RunnerStateType.IDLE

var b_was_grounded: bool = false

func is_in_state(state_type) -> bool:
    if state_type is int:
        return current_type == state_type
    elif state_type is Array:
        return current_type in state_type
    else:
        return false

func _set_state(state_type: int, state: RunnerState):
    states[state_type] = state

func _state(state_type: int) -> RunnerState:
    return states[state_type] as RunnerState

func _current_state() -> RunnerState:
    return states[current_type] as RunnerState

# Initialize the state machine and all the states.
func init(runner):
    self.runner = runner

    _set_state(RunnerStateType.IDLE, IdleState.new())
    _set_state(RunnerStateType.DASH, DashState.new())
    _set_state(RunnerStateType.RUNNING, RunningState.new())
    _set_state(RunnerStateType.AIRBORNE, AirborneState.new())
    _set_state(RunnerStateType.AIRDASH, AirdashState.new())
    _set_state(RunnerStateType.JUMPSQUAT, JumpsquatState.new())

    _set_state(RunnerStateType.ATT_FORWARD,
        AttackState.new(runner.get_node("moveset/normal_forward")))
    _set_state(RunnerStateType.ATT_UAIR,
        AttackState.new(runner.get_node("moveset/normal_up")))
    _set_state(RunnerStateType.ATT_DAIR,
        AttackState.new(runner.get_node("moveset/normal_down")))

    _set_state(RunnerStateType.SPECIAL, SpecialState.new())

    var state = _state(RunnerStateType.IDLE)
    state.allow_dropdown()
    state.allow_dash_cancel()
    state.allow_jump_cancel()
    state.allow_air_cancel()
    state.allow_airdash_cancel()
    state.allow_attack_cancel()
    state.allow_special_cancel()

    state = _state(RunnerStateType.DASH)
    state.allow_dropdown()
    state.allow_dash_cancel()
    state.allow_jump_cancel()
    state.allow_edge_cancel()
    state.allow_idle_cancel()
    state.allow_airdash_cancel()
    state.allow_attack_cancel()
    state.allow_special_cancel()

    state = _state(RunnerStateType.RUNNING)
    state.allow_dropdown()
    state.allow_dash_cancel()
    state.allow_jump_cancel()
    state.allow_edge_cancel()
    state.allow_idle_cancel()
    state.allow_airdash_cancel()
    state.allow_attack_cancel()
    state.allow_special_cancel()

    state = _state(RunnerStateType.AIRBORNE)
    state.allow_jump_cancel()
    state.allow_walljump_cancel()
    state.allow_land_cancel()
    state.allow_fastfall()
    state.allow_airdash_cancel()
    state.allow_attack_cancel()
    state.allow_special_cancel()

    state = _state(RunnerStateType.AIRDASH)
    state.allow_jump_cancel()
    state.allow_walljump_cancel()
    # state.allow_land_cancel()
    state.allow_airdash_cancel()
    state.allow_attack_cancel()
    state.allow_special_cancel()

    state = _state(RunnerStateType.JUMPSQUAT)
    state.allow_airdash_cancel()
    state.allow_attack_cancel()
    state.allow_special_cancel()





# State Changers
#================================================================================

# Queue a state to transition to.
func queue_state(state_type: int) -> void:
    # print("queued state: %s" % RunnerStateType.get_name(state_type))
    # queued_state_type = state_type
    set_state(state_type)

# Set the state of the handle
func set_state(state_type):
    # if state_type == current_type: return
    if runner and state_type in states:

        var old_state_type = current_type
        var new_state = states[state_type]

        if new_state.can_start(runner):
            # Call on_end() of previous state

            var current_state = _current_state()

            if current_type:
                current_state.on_end(state_type, runner, runner.fsm)

            current_type = state_type
            current_state = states[current_type]
            current_state.time = 0.0
            current_state.tick = 0
            b_was_grounded = false

            # Call on_start() of new state

            var old_state_name = RunnerStateType.get_name(old_state_type)
            var new_state_name = RunnerStateType.get_name(state_type)
            emit_signal("state_changed", new_state_name, old_state_name)
            current_state.on_start(old_state_type, runner, runner.fsm)

func process(delta):
    if runner == null: return

    var state = _current_state()

    # THE BELOW CHECKS WILL APPLY TO ALL STATES
    #------------------------------------------

    # goto airborne if not grounded and was previously grounded.
    if runner.is_grounded():
        b_was_grounded = true

    if state.b_can_edge_cancel and b_was_grounded and not runner.is_grounded():
        runner.fsm.goto_airborne()

    if state.b_can_air_cancel and not runner.is_grounded():
        runner.fsm.goto_airborne()

    # Switch player to any grounded state if grounded.
    try_land_cancel(state)
    
    # allow airdash
    try_airdash_cancel(state)

    # allow attack
    if state.b_can_attack_cancel and runner.pressed_attack():
        runner.action_attack()

    # allow special attack
    if state.b_can_special_cancel and runner.pressed_special():
        runner.action_special()

    # Check if the player wants to drop-down a platform.
    if state.b_can_dropdown and runner.pressed_down():
        runner.action_dropdown()

    # Check if the player wants to do a jump (air or grounded).
    try_jump_cancel(state)

    # Check if the player wants to do a walljump.
    try_walljump_cancel(state)

    # Check if the player wants to fastfall.
    try_fastfall(state)

    # Check if the player wants to dash.
    # sensitivity: sets how hard you need to press the direction
    #              for it to register (lower = more sensitive)
    # require_neutral: if true, ignore dash inputs that don't go
    #                  through the center of the movement axis
    # if (
    #     runner.pressed_left_thru_neutral()
    #     or runner.pressed_right_thru_neutral()
    # ):
    if state.b_can_dash_cancel and (runner.pressed_left() or runner.pressed_right()):
        runner.action_dash()

    # Check if player is trying to not move (no movement input)
    if state.b_can_idle_cancel and runner.is_axis_neutral():
        runner.action_neutral()

    state = _current_state()

    # transition to queued state if any
    if queued_state_type != null:
        set_state(queued_state_type)
        queued_state_type = null

    # update current state
    var next_state = state.on_update(delta, runner, self)
    if next_state != null:
        print("next state: %s" % next_state)
        set_state(next_state)

    state.tick += 1
    state.time += delta

func try_airdash_cancel(state):
    if state.b_can_airdash_cancel and runner.pressed_airdash():
        runner.action_airdash()

func try_land_cancel(state):
    if state.b_can_land_cancel and runner.is_grounded():
        goto_grounded()
        return true
    return false

func try_fastfall(state):
    if state.b_can_fastfall and runner.pressed_down():
        runner.action_fastfall()
        return true
    return false

func try_jump_cancel(state):
    if state.b_can_jump_cancel and runner.pressed_jump():
        runner.action_jump()
        return true
    return false

func try_walljump_cancel(state):
    if state.b_can_walljump_cancel:
        runner.action_walljump()
        return true
    return false

func goto_idle():      queue_state(RunnerStateType.IDLE)
func goto_running():   queue_state(RunnerStateType.RUNNING)
func goto_dash():      queue_state(RunnerStateType.DASH)

func goto_jumpsquat(): queue_state(RunnerStateType.JUMPSQUAT)
func goto_airborne():  queue_state(RunnerStateType.AIRBORNE)

func goto_airdash():   queue_state(RunnerStateType.AIRDASH)

func goto_attack():    queue_state(RunnerStateType.ATTACK)
func goto_special():   queue_state(RunnerStateType.SPECIAL)
        
# Set the runner state to either idle, running or dash
# depending on the current state of the runner.
func goto_grounded() -> void:
    # melee-like behavior
    #goto_idle()

    # more forgiving behavior
    if runner.is_facing_forward():
        goto_running()
    else:
        goto_idle()

# Set the runner state to either idle, running, dash, or airborne
# depending on the current state of the runner.
func goto_any():
    if runner.is_grounded():
        goto_grounded()
    else:
        goto_airborne()

# State Transition Setters
#===============================================================================
