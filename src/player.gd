extends Runner

var GhostPlayer = load("res://scenes/GhostPlayer.tscn")

var replay_frames = {}
var tick = 0

var ghost = null

func _ready():
    print("buffer: %s " % buffer)

func _physics_process(delta):

    if game.game_paused:
        return

    if Input.is_action_just_pressed("reset"):
        reset()
        return

    for key in ["key_up", "key_down", "key_left", "key_right", "key_jump", "key_dodge", "grapple", "shoot"]:
        var value = Input.get_action_strength(key)
        buffer.trigger_press(key, value)

    replay_frames[tick] = buffer.input_map.duplicate()
    tick += 1

    debug_info.text = "speed: %3.2f (x=%3.2f, y=%3.2f)\nstate: %s" % [velocity.length(), velocity.x, velocity.y, state_name]

func reset():

    tick = 0
    .reset()

    if game.is_best_time():
        if ghost == null:
            ghost = create_ghost()
        else:
            ghost.init(replay_frames.duplicate(true))
    else:
        if ghost != null:
            ghost.reset()

    replay_frames = {}

    game.reset_timer()
    game.get_enemies().reset()

    # ._physics_process(delta)

func create_ghost():

    var ghost = GhostPlayer.instance()
    get_tree().root.get_node("World").add_child(ghost)
    ghost.init(replay_frames.duplicate(true))

    return ghost
    
