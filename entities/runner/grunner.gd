#================================================================================
# Ghost Runner
#
# A runner controlled by recorded inputs.
#================================================================================
class_name GhostRunner
extends Runner 

signal replay_finish

# if any position deviation detected over this value,
# fix the position
const MIN_DEVIATION = 0.0

var replay = null
var initial_conditions = null
var replay_frames = null
var pos_frames = null
var last_tick = 0

var playing = false

var replay_finished = false

func _ready():
    # print("buffer: %s " % buffer)
    no_damage = true
    no_effects = true
    ignore_enemy_hp = true
    visible = false

    connect("replay_finish", Game, "replay_playback_stop")

func load_replay(new_replay):
    replay = new_replay
    last_tick = replay.input_frames.keys().max()

# stop playing this ghost
func stop():
    print("[ghost] stopped replay")
    $sprite.visible = false
    playing = false

func restart():
    print("[ghost] restarting replay")
    .restart()
    visible = true
    replay_finished = false
    position = replay.start_position
    velocity = replay.start_velocity
    fsm.current_type = replay.start_state_type
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
            print("[ghost] deviation detected! fixing position...")
            position = expected_pos
            velocity = expected_vel

    # read inputs from replay frames
    if tick in replay.input_frames:
        var action_map = replay.input_frames[tick]
        for action in action_map:
            input.update_action(action, action_map[action])
    elif tick > last_tick and not replay_finished:
        print("[ghost] reached end of replay (tick = %s)" % tick)
        replay_finished = true
        playing = false
        emit_signal("replay_finish")
    else:
        push_warning("[ghost] missing tick: %s" % tick)

    # else:
    #     restart()
    #     return

# don't play any sounds
func play_sound(sound, volume = 0.0, pitch = 1.0, force = false):
    pass
