class_name ReplayManager

## reference to GameState
var game

## the current replay being recorded
var replay: Replay

## a stored, complete replay that is ready for playback
var saved_replay: Replay

## the Ghost used to playback the stored replay
var ghost_character: Ghost

## if true, a replay is currently being recorded
var b_is_recording = false


## if true, enable playback of a loaded replay
@export var playback_enabled := true

## if true, enable recording inputs of a player on level start
@export var recording_enabled := true


func _init(game):
	self.game = game

##
## Create a new replay of a character to be recorded.
##
func _create_replay(character):
	return Replay.new(character)

##
## Start recording a replay.
##
func start_recording():
	if recording_enabled and not b_is_recording:
		replay = _create_replay(game.get_player())
		game.get_player().replay = replay
		b_is_recording = true
		print("[demo] recording started")
		game.debug_ping("recording started")

##
## Stop recording a replay.
##
func stop_recording():
	if b_is_recording:
		b_is_recording = false
		print("[demo] recording stopped")
		game.debug_ping("recording stopped")

##
## Stop recording and store the resulting replay.
##
func save_recording():
	replay.stop_recording()
	
	print("[demo] new replay saved! (%d frames)" % len(replay.input_frames))
	print("    position: %s" % replay.start_position)
	print("    velocity: %s" % replay.start_velocity)
	print("    state: %s" % replay.start_state_type)
	
	saved_replay = replay
	replay = null
	
	game.debug_ping("recording saved")

##
## Start ghost playback of the stored replay.
##
func start_playback():
	if playback_enabled and is_instance_valid(saved_replay) and saved_replay.b_ready_for_playback:
		print("[demo] playback started")

		if not is_instance_valid(ghost_character):
			print("[ghost] creating new ghost")
			ghost_character = GameState.Ghost.instantiate()
			ghost_character._gamestate = game
			game.get_node("/root/main/viewport_screen").add_child(ghost_character)

		ghost_character.load_replay(saved_replay)
		ghost_character.restart()
	elif not is_instance_valid(saved_replay):
		print("[demo] no replay to playback!")
	elif not saved_replay.b_ready_for_playback:
		print("[demo] tried to playback, replay not ready!")
	else:
		print("[demo] cannot playback replay!")

##
## Stop ghost playback of the stored replay.
##
func stop_playback():
	print("[demo] playback stopped")
	if is_instance_valid(ghost_character):
		ghost_character.stop()

##
## Stop ghost playback and remove the stored replay.
## Frees the ghost instance.
##
func clear_playback():
	if is_instance_valid(ghost_character):
		print("[demo] playback stopped and recording cleared")
		ghost_character.queue_free()
		ghost_character = null
		saved_replay = null
