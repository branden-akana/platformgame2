extends Node2D
class_name RunnerState

var runner
var buffer: InputBuffer
var game: Game

var time: float = 0.0
var tick: int = 0

func init(runner_):
    self.runner = runner_
    self.buffer = runner.buffer
    self.game = $"/root/World" as Game
    on_init()

# Set the state of the handle
func set_state(state_name):
    if state_name in runner.states:
        on_end()
        var old_state_name = runner.state_name
        runner.state_name = state_name
        runner.state.time = 0.0
        runner.state.tick = 0
        runner.state.on_start(old_state_name)

# Sets the state to a "default" state.
func reset_state():
    if runner.is_on_floor():
        runner.play_particle_effect(runner.DustParticles)
        # var axis = buffer.get_action_axis()
        # if axis.x != 0:
            # set_state("running")
        # else:
            # set_state("idle")
        set_state("idle")
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

# called when this state is instantiated
func on_init():
    pass

# called at the beginning of the state
func on_start(state_name):
    pass

# called every physics process
func on_update(_delta: float):
    pass

# called at the end of the state
func on_end():
    pass

