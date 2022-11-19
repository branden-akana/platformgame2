#===============================================================================
# Replay
#
# Contains data checked a player's input as well as their pos/vel per tick.
# Also contains the player's "initial conditions" including their starting pos/vel,
# state, and initial inputs.
#===============================================================================
class_name Replay


# how often (in ticks) to sync the character
# with the replay during playback
const SYNC_INTERVAL = 20

var b_ready_for_playback = false

# the character's starting position
var start_position      

# the character's starting velocity
var start_velocity      

# the character's starting state
var start_state_type    

# the init state of the character's input
var start_input         

var input_frames = {}
var sync_frames = {}


func _init(character):
	start_position = character.position
	start_velocity = character.velocity
	start_state_type = character.fsm.current_type
	start_input = character.input.duplicate()


# record this character's state checked n tick
func record_tick(character, n):
	# duplicate this character's input action map
	# (map of current inputs)
	input_frames[n] = character.input.action_map.duplicate()

	if n % SYNC_INTERVAL == 0:
		sync_frames[n] = [character.position, character.velocity]


# mark this recording as ready for playback
func stop_recording():
	b_ready_for_playback = true
