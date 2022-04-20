#===============================================================================
# Replay
#
# Contains data on a player's input as well as their pos/vel per tick.
# Also contains the player's "initial conditions" including their starting pos/vel,
# state, and initial inputs.
#===============================================================================
class_name Replay

var start_position      # the runner's starting position
var start_velocity      # the runner's starting velocity
var start_state_type    # the runner's starting state
var start_input         # the init state of the runner's input

var initial_conditions
var input_frames
var pos_frames

# Create a new replay.
func init(init_conds, input_frames_, pos_frames_):

    start_position = init_conds.position
    start_velocity = init_conds.velocity
    start_state_type = init_conds.state_type
    start_input = init_conds.input

    input_frames = input_frames_
    pos_frames = pos_frames_
