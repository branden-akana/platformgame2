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

var states = {
    State.IDLE: IdleState.new(),
    State.DASH: DashState.new(),
    State.RUNNING: RunningState.new(),
    State.AIRBORNE: AirborneState.new(),
    State.AIRDASH: AirdashState.new(),
    State.JUMPSQUAT: JumpsquatState.new(),

    State.ATTACK: AttackState.new(),
    State.SPECIAL: SpecialState.new(),
}

var runner
var current_type = State.IDLE
var current_state setget , get_current_state

func get_current_state():
    return states[current_type]

# Initialize the state machine and all the states.
func init(runner):
    self.runner = runner


# State Changers
#================================================================================

# Set the state of the handle
func set_state(state_type):
    # if state_type == current_type: return

    if runner and state_type in states:
        var old_state_name = current_type
        var new_state = states[state_type]
        if new_state.can_start(runner):
            # Call on_end() of previous state
            if current_state:
                current_state.on_end(state_type, runner, runner.fsm)
            current_type = state_type
            current_state = states[current_type]
            current_state.time = 0.0
            current_state.tick = 0
            # Call on_start() of new state
            current_state.on_start(old_state_name, runner, runner.fsm)
            print("state: %s -> %s" % [State.get_name(old_state_name), State.get_name(state_type)])

func process(delta):
    if runner == null: return

    # process the current state
    current_state.process(delta, runner, self)

func goto_idle():      set_state(State.IDLE)
func goto_running():   set_state(State.RUNNING)
func goto_dash():      set_state(State.DASH)

func goto_jumpsquat(): set_state(State.JUMPSQUAT)
func goto_airborne():  set_state(State.AIRBORNE)

func goto_airdash():   set_state(State.AIRDASH)

func goto_attack():    set_state(State.ATTACK)
func goto_special():   set_state(State.SPECIAL)
        
# Set the runner state to either idle, running or dash
# depending on the current state of the runner.
func goto_grounded():
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
