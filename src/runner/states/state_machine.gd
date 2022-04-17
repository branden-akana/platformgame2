class_name StateMachine

var states = {
    State.IDLE: IdleState.new(),
    State.DASH: DashState.new(),
    State.RUNNING: RunningState.new(),
    State.AIRBORNE: AirborneState.new(),
    State.AIRDASH: AirdashState.new(),
    State.JUMPSQUAT: JumpsquatState.new(),

    State.ATTACK: AttackState.new(),
    State.SPECIAL: SpecialState.new(),

    # unused
    State.SHOOTCOIN: ShootCoinState.new(),
    State.GRAPPLE: GrappleState.new(),
    State.REELING: ReelingState.new(),
}

var runner
var current_type = State.IDLE
var current_state setget , get_current_state

func get_current_state():
    return states[current_type]

# Initialize the state machine and all the states.
func init(runner):
    self.runner = runner

    for state in states.values():
        state.init(runner)

# State Changers
#================================================================================

# Set the state of the handle
func set_state(state_type):
    if runner and state_type in states:
        var old_state_name = current_type
        var new_state = states[state_type]
        if new_state.can_start():
            # Call on_end() of previous state
            if current_state:
                current_state.on_end()
            current_type = state_type
            current_state = states[current_type]
            current_state.time = 0.0
            current_state.tick = 0
            # Call on_start() of new state
            current_state.on_start(old_state_name)
            print("state: %s -> %s" % [State.get_name(old_state_name), State.get_name(state_type)])

func goto_idle():      set_state(State.IDLE)
func goto_running():   set_state(State.RUNNING)
func goto_dash():      set_state(State.DASH)

func goto_jumpsquat(): set_state(State.JUMPSQUAT)
func goto_airborne():  set_state(State.AIRBORNE)

func goto_airdash():   set_state(State.AIRDASH)

func goto_attack():    set_state(State.ATTACK)
func goto_special():   set_state(State.SPECIAL)
        
# Set the runner state to either idle, running, dash, or airborne
# depending on the current state of the runner.
func goto_idle_or_dash():
    if runner.is_on_floor():
        if round(current_state.input.get_axis().x) == 0:
            goto_idle()
        elif current_state.is_facing_forward():
            goto_running()
        else:
            goto_dash()
    else:
        goto_airborne()

# Set the runner state to either idle, running, or airborne.
func goto_idle_or_run():
    if runner.is_on_floor():
        if round(current_state.input.get_axis().x) == 0:
            goto_idle()
        else:
            goto_running()
    else:
        goto_airborne()
