#===============================================================================
# Replay
#
# Contains data checked a player's input as well as their pos/vel per tick.
# Also contains the player's "initial conditions" including their starting pos/vel,
# state, and initial inputs.
#===============================================================================
class_name Replay


## how often (in ticks) to sync the character with the replay during playback
const SYNC_INTERVAL = 20

## if true, this replay is complete and ready for playback
var b_ready_for_playback := false

## the character's starting position
var start_position: Vector2

## the character's starting velocity
var start_velocity: Vector2

## the character's starting state
var start_state_type: StringName

## the init state of the character's input
var start_input: CharacterInput

## the character's state of inputs per tick
var input_frames = {}

## the character's pos & vel per sync interval
var sync_frames = {}


func _init(character):
	start_position = character.position
	start_velocity = character.velocity
	start_state_type = character.fsm.current_state_name
	start_input = character.input.duplicate()

##
## Record this character's state at n tick.
##
func record_tick(character, n):
	if not b_ready_for_playback:
		# store character's current inputs
		input_frames[n] = character.input.action_map.duplicate()

		# store character's position & velocity on an interval (for desync detection)
		if n % SYNC_INTERVAL == 0:
			sync_frames[n] = [character.position, character.velocity]

##
## Stop any further character recording.
## Marks this replay as complete and ready for playback.
##
func stop_recording():
	b_ready_for_playback = true
