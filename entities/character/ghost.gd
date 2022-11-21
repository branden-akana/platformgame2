#================================================================================
# Ghost Character
#
# A character controlled by recorded inputs.
#================================================================================

class_name Ghost extends Character 

signal replay_finished

## if any position deviation detected over this value, sync the ghost
const MIN_DEVIATION = 0.0

## the number of times the ghost desynced
var num_desyncs := 0

var replay = null
var initial_conditions = null
var replay_frames = null
var pos_frames = null
var last_tick = 0

var playing = false

var is_replay_finished = false


func _ready():
    # print("buffer: %s " % buffer)
    no_damage = true
    no_effects = true
    ignore_enemy_hp = true
    visible = false

    replay_finished.connect(stop)

##
## Sets the replay that this ghost will play back.
##
func load_replay(new_replay: Replay) -> void:
    replay = new_replay
    last_tick = replay.input_frames.keys().max()

##
## Stops replay playback and hide this ghost.
##
func stop() -> void:
    print("[ghost] stopped replay")
    visible = false
    playing = false

##
## Starts replay playback (or restarts, if already playing).
##
func restart() -> void:
    print("[ghost] restarting replay")
    super.restart()
    visible = true
    is_replay_finished = false

    position = replay.start_position
    velocity = replay.start_velocity
    fsm.current_state_name = replay.start_state_type
    set_input_handler(replay.start_input)

    playing = true


func pre_process(_delta):

    if not playing:
        return

    if tick in replay.sync_frames:
        var expected_pos = replay.sync_frames[tick][0]
        var expected_vel = replay.sync_frames[tick][1]
        var delta_pos = position.distance_to(expected_pos)
        # var delta_vel = velocity.distance_to(expected_vel)
        # print("Frame %d: delt pos = %0.2f, delt vel = %0.2f" % [tick, delta_pos, delta_vel])
        if delta_pos > MIN_DEVIATION:
            num_desyncs += 1
            position = expected_pos
            velocity = expected_vel

    # read inputs from replay frames
    if tick in replay.input_frames:
        var action_map = replay.input_frames[tick]
        for action in action_map:
            input.update_action(action, action_map[action])

    elif tick > last_tick and not is_replay_finished:
        # accuracy of playback
        var acc := num_desyncs / float(len(replay.sync_frames)) * 100

        print("[ghost] playback finished")
        print("    tick:    %s" % tick)
        print("    desyncs: %d (%.2f%% accuracy)" % [num_desyncs, acc])

        is_replay_finished = true
        playing = false
        replay_finished.emit()

    else:
        push_warning("[ghost] missing tick: %s" % tick)


# don't play any sounds
func play_sound(sound, volume = 0.0, pitch = 1.0, force = false):
    pass
