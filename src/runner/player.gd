extends Runner
class_name Player

var initial_conditions = null
var replay_frames = {}

# frames where the player's pos and vel are stored,
# used to check for ghost replay deviation
var pos_frames = {}
var fix_interval = 20

var ghost = null

func _ready():
    connect("walking", Sound, "play", ["walk", -20, 0.8, true, false])
    connect("stop_walking", Sound, "stop", ["walk"])
    connect("jump", Sound, "play", ["jump", -10, 1, false])
    connect("land", Sound, "play", ["land", -20])
    connect("hit", Sound, "play", ["hit", -10])
    connect("dash", Sound, "play", ["walk", -20, 0.8, false, true])

    # sprite setup
    Game.reparent_to_fg1(sprite)

func pre_process(delta):

    # update player color
    if airdashes_left <= 0:
        sprite.modulate = Color(0.3, 0.3, 0.3)
    else:
        sprite.modulate = Color(1.0, 1.0, 1.0)

    # needed as sometimes the walking sound does not stop
    if state_name != "running":
        Sound.stop("walk")

    if Game.game_paused:
        return

    if Input.is_action_just_pressed("reset"):
        player_restart()
        return

    # camera panning
    # if is_on_floor():
    #     var camera_offset = Vector2(0, 0)
    #     var down_held_time = buffer.get_time_held("key_down")
    #     var up_held_time = buffer.get_time_held("key_up")

    #     if down_held_time and buffer.get_action_strength("key_down") > 0.9:  # pan down
    #         # print("down held: %0.2f" % down_held_time)
    #         camera_offset = lerp(
    #             Vector2(0, 0), Vector2(0, 80),
    #             ease(clamp((down_held_time - 1.0) / 0.5, 0.0, 1.0), -2.8)
    #         )
    #     elif up_held_time and buffer.get_action_strength("key_up") > 0.9:  # pan up
    #         # print("up held: %0.2f" % up_held_time)
    #         camera_offset = lerp(
    #             Vector2(0, 0), Vector2(0, -80),
    #             ease(clamp((up_held_time - 1.0) / 0.5, 0.0, 1.0), -2.8)
    #         )

    #     Game.get_camera().set_offset(camera_offset)

    # process player input
    for key in ["key_up", "key_down", "key_left", "key_right", "key_jump", "key_dodge", "grapple", "shoot"]:
        var value = Input.get_action_strength(key)
        buffer.update_action(key, value)

    if Game.is_recording:
        # record initial conditions (position, velocity, etc.)
        if tick == 0:
            initial_conditions = get_current_conditions()

        # record pos/vel periodically (for replay pos checking)
        if tick % fix_interval == 0:
            pos_frames[tick] = [position, velocity]

        # record current inputs for this frame
        replay_frames[tick] = buffer.input_map.duplicate()

# Do an animated restart
func player_restart():
    # pause during fadeout
    yield(Game.pause_and_fade_out(0.2), "completed")

    Game.replay_stop_recording()
    restart()
    Game.restart_level()
    Game.replay_start_recording()

    # unpause after fadein
    yield(Game.fade_in_and_unpause(0.2), "completed")

func hurt(damage = 100, respawn_point = null):
    # pause during fadeout
    yield(Game.pause_and_fade_out(0.2), "completed")

    .hurt(damage, respawn_point)

    # unpause after fadein
    yield(Game.fade_in_and_unpause(0.2), "completed")

func restart():

    # reset player to start point
    .restart()
    if Game.replay:
        Game.replay_playback_start()

    # clear replay data
    replay_frames = {}
    pos_frames = {}

# func respawn(pos):
#     .respawn(pos)

func export_replay():
    var replay = Replay.new()
    replay.init(initial_conditions, replay_frames, pos_frames)
    return replay
