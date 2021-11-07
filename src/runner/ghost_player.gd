extends Runner 
class_name GhostPlayer

signal replay_finish

# if any position deviation detected over this value,
# fix the position
const MIN_DEVIATION = 0.0

var replay = null
var initial_conditions = null
var replay_frames = null
var pos_frames = null

var playing = false

var replay_finished = false

func _ready():
    # print("buffer: %s " % buffer)
    no_damage = true
    no_effects = true
    ignore_enemy_hp = true
    sprite.visible = false

    connect("replay_finish", Game, "replay_playbaadack_stop")

func load_replay(new_replay):
    replay = new_replay

# stop playing this ghost
func stop():
    print("[ghost] stopped replay")
    sprite.visible = false
    playing = false

func restart():
    print("[ghost] restarting replay")
    .restart()
    sprite.visible = true
    replay_finished = false
    position = replay.start_position
    velocity = replay.start_velocity
    state_name = replay.start_state_name
    set_input_handler(replay.start_input)
    playing = true

func pre_process(_delta):

    if not playing:
        return

    if tick in replay.pos_frames:
        var expected_pos = replay.pos_frames[tick][0]
        var expected_vel = replay.pos_frames[tick][1]
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
    else:
        if not replay_finished:
            print("[ghost] reached end of replay")
            replay_finished = true
            emit_signal("replay_finish")

    # else:
    #     restart()
    #     return

# don't play any sounds
func play_sound(sound, volume = 0.0, pitch = 1.0, force = false):
    pass
