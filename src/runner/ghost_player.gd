extends Runner 
class_name GhostPlayer

signal replay_finish

# if any position deviation detected over this value,
# fix the position
const MIN_DEVIATION = 0.0

var initial_conditions = null
var replay_frames = null
var pos_frames = null

var replay_finished = false

func _ready():
    # print("buffer: %s " % buffer)
    no_damage = true
    no_effects = true
    ignore_enemy_hp = true
    sprite.visible = false

    connect("replay_finish", self, "stop")

func init(initial_conditions_, replay_frames_, pos_frames_):
    initial_conditions = initial_conditions_
    replay_frames = replay_frames_
    pos_frames = pos_frames_
    print("[ghost] new replay loaded! (%d frames)" % len(replay_frames))
    print("    position: %s" % initial_conditions.position)
    print("    velocity: %s" % initial_conditions.velocity)
    print("    state: %s" % initial_conditions.state_name)

# stop playing this ghost
func stop():
    print("[ghost] stopped replay")
    sprite.visible = false

func restart():
    print("[ghost] restarting replay")
    .restart()
    sprite.visible = true
    replay_finished = false
    position = initial_conditions.position
    velocity = initial_conditions.velocity
    state_name = initial_conditions.state_name

func pre_process(_delta):
    
    if tick == 0:
        set_input_buffer(initial_conditions.buffer.duplicate())

    if tick in pos_frames:
        var expected_pos = pos_frames[tick][0]
        var expected_vel = pos_frames[tick][1]
        var delta_pos = position.distance_to(expected_pos)
        # var delta_vel = velocity.distance_to(expected_vel)
        # print("Frame %d: delt pos = %0.2f, delt vel = %0.2f" % [tick, delta_pos, delta_vel])
        if delta_pos > MIN_DEVIATION:
            print("[ghost] deviation detected! fixing position...")
            position = expected_pos
            velocity = expected_vel

    # read inputs from replay frames
    if tick in replay_frames:
        var input_map = replay_frames[tick]
        for input in input_map:
            buffer.update_action(input, input_map[input])
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
