#===============================================================================
# Replay
#
# Contains data on a player's input as well as their pos/vel per tick.
# Also contains the player's "initial conditions" including their starting pos/vel,
# state, and initial inputs.
#===============================================================================
class_name Replay


# how often (in ticks) to sync the runner
# with the replay during playback
const SYNC_INTERVAL = 20

var b_ready_for_playback = false

# the runner's starting position
var start_position      

# the runner's starting velocity
var start_velocity      

# the runner's starting state
var start_state_type    

# the init state of the runner's input
var start_input         

var input_frames = {}
var sync_frames = {}


func _init(runner):
    start_position = runner.position
    start_velocity = runner.velocity
    start_state_type = runner.fsm.current_type
    start_input = runner.input.duplicate()


# record this runner's state on n tick
func record_tick(runner, n):
    # duplicate this runner's input action map
    # (map of current inputs)
    input_frames[n] = runner.input.action_map.duplicate()

    if n % SYNC_INTERVAL == 0:
        sync_frames[n] = [runner.position, runner.velocity]


# mark this recording as ready for playback
func stop_recording():
    b_ready_for_playback = true
