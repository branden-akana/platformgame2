class_name ReplayManager

const GhostPlayer = preload("res://entities/runner/grunner.tscn")

var game

var replay
var saved_replay

var ghost_runner

var b_is_recording = false

func _init(game):
    self.game = game

# create a new replay of a runner to be recorded
func create_replay(runner):
    return Replay.new(runner)


# Start recording a replay.
func start_recording():
    if not b_is_recording:
        replay = create_replay(game.get_player())
        game.get_player().replay = replay
        b_is_recording = true
        print("[demo] recording started")
        game.debug_ping("recording started")


# Stop recording a replay.
func stop_recording():
    if b_is_recording:
        b_is_recording = false
        print("[demo] recording stopped")
        game.debug_ping("recording stopped")


func save_recording():
    replay.stop_recording()
    
    print("[demo] new replay saved! (%d frames)" % len(replay.input_frames))
    print("    position: %s" % replay.start_position)
    print("    velocity: %s" % replay.start_velocity)
    print("    state: %s" % replay.start_state_type)
    
    saved_replay = replay
    replay = null
    
    game.debug_ping("recording saved")


# Start playback of the last replay (using a ghost).
func start_playback():
    if is_instance_valid(saved_replay) and saved_replay.b_ready_for_playback:
        print("[demo] playback started")

        if not is_instance_valid(ghost_runner):
            print("[ghost] creating new ghost")
            ghost_runner = GhostPlayer.instantiate()
            game.get_node("/root/main").add_child(ghost_runner)

        ghost_runner.load_replay(saved_replay)
        ghost_runner.restart()
    elif not is_instance_valid(saved_replay):
        print("[demo] no replay to playback!")
    else:
        print("[demo] cannot playback replay while still recording!")


func stop_playback():
    print("[demo] playback stopped")
    if is_instance_valid(ghost_runner):
        ghost_runner.stop()


# Stop playback.
func clear_playback():
    print("[demo] recording cleared")
    if is_instance_valid(ghost_runner):
        print("[ghost] deleting ghost")
        ghost_runner.queue_free()
        ghost_runner = null
        saved_replay = null


