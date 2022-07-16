extends Node2D

signal paused
signal unpaused
signal level_restarted
signal level_cleared
signal scene_loaded
signal post_ready
signal debug_mode_changed

const DisplayManager = preload("res://effects/display_manager.tscn")
const Textbox = preload("res://ui/textbox.tscn")
const Level_TestHub = preload("res://levels/test_hub.tscn")
const PlayerRunner = preload("res://entities/runner/prunner.tscn")

# list of pause reasons
enum PauseRequester {
    SCREEN_CHANGE,  # used during screen transitions
    MENU            # used for when player enters menu
}

enum DebugMode {NORMAL, DEBUG, HITBOXES}

# total ticks for the currently loaded level
var tick: int = 0

# TODO: move these into a record/timer class

# the total amount of time elapsed for the current level until completion
var time: float = 0.0

# the best completion time
var time_best: float = INF

var time_paused: bool = false

# total amount of times the player died in the current level
var num_deaths = 0

# game pausing variables
var game_pause_requests = []  # contains refs to nodes that want to pause the game
var game_paused: bool setget , is_paused
var menu

# amount of time user has held pause
var pause_hold_time = 0.0

# the current level that is loaded
onready var current_level = get_level()

# the current room that the player is in
var current_room = null setget set_current_room

# used to draw sprite text
onready var spritefont = SpriteLabel.new()

onready var replay_manager = ReplayManager.new()

# flags
var practice_mode = false
var is_recording = true   # if true, record the player
var is_in_menu = false    # if true, remove control from the player

var debug_mode: int = DebugMode.NORMAL

func _ready():
    add_child(spritefont)

    replay_manager.init(self)

    # Game initialization stuff

    Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

    print("Feel free to minimize this window! It needs to be open for some reason to avoid a crash.")
    
    # initialize menu
    menu = HUD.get_node("main_menu")

    # initialize player
    var player
    if $"/root/main".has_node("player"):  # try to find a player
        player = get_player()  
    else:  # or manually spawn the player
        player = PlayerRunner.instance()
        $"/root/main".add_child(player)

    player.connect("died", self, "on_player_death")
    yield(player, "ready")

    connect("level_cleared", self, "on_level_clear")

    reinitialize_game()
    
    # wait for editor nodes to free
    yield(free_editor_nodes(), "completed")
    
    # initialize post process manager
    #var pp = DisplayManager.instance()
    #$"/root/main".add_child(pp)
    
    emit_signal("post_ready")
    
    
func free_editor_nodes():
    # remove all "editor only" nodes
    for node in get_tree().get_nodes_in_group("editor_only"):
        yield(node, "tree_exiting")
    yield(get_tree(), "idle_frame")


# Initialize the game. Use after loading a new level.
func reinitialize_game():

    tick = 0

    # reset best time / ghost
    clear_best_times()
    replay_manager.clear_playback()

    restart_player()
    restart_level()
    
# Restart the level. Use to reset the state of just the level.
func restart_level():

    # stop replay recording
    replay_manager.stop_recording()

    # reset stats / timers
    num_deaths = 0
    reset_timer()

    # reset state of the level
    reset_enemies()
    reset_entities()

    # reset camera
    get_camera().init()

    # start replay recording and playback
    replay_manager.start_recording()
    replay_manager.start_playback()
    
    emit_signal("level_restarted")

# Restart the current room.
func restart_room():
    if is_instance_valid(current_room):
        current_room.reset_room()

func restart_player():
    # set start position
    get_player().restart()

func load_scene(level):
    # debug_log("loading new scene...")
    # debug_log("fading out...")
    yield(pause_and_fade_out(0.5), "completed")
    call_deferred("_load_scene", level)
    # yield(self, "scene_loaded")
    # debug_log("fading in...")
    yield(fade_in_and_unpause(0.5), "completed")
    # debug_log("finished!")

func _load_scene(level_path):

    # debug_log("loading new scene")

    # load the new scene
    var level = level_path.instance()
    level.name = "level"

    # remove current scene and add new one
    # debug_log("removing old scene")

    get_level().free()

    # debug_log("adding new scene as child")

    $"/root/main".add_child(level)
    current_level = level

    # debug_log("restarting level...")

    # reinit the game
    reinitialize_game()

    # debug_log("new scene loaded")

    emit_signal("scene_loaded")

# Level/Room Functions
# ========================================================================

func get_level() -> Level:
    return $"/root/main/level" as Level

# Get a list of all rooms in the current level.
func get_rooms() -> Array:
    return get_tree().get_nodes_in_group("room")

# Sets the current room to focus on.
#
# The camera will now be bound within this room.
# If smooth_transition is true, briefly pause the game and transition
# the camera to the new room. Otherwise, move the camera to the
# new room instantly.
func set_current_room(room, do_transition = true):
    # print("entered new room")
    # NOOP if screen is invalid or is already current screen
    if room == null or current_room == room: return
    current_room = room

    # lock camera to this screen area
    var bounds = room.get_bounds()
    get_camera().set_bounds(bounds[0], bounds[1], do_transition, room.palette_idx)


# Attempt to find a room at this position. If none is found, return null.
func get_room_at_point(pos):
    # print("finding %s in %s" % [pos, get_rooms()])
    for room in get_rooms():
        # get this room's collision box
        var collision = room.get_node("collision")
        var shape = collision.shape

        # create a rect with the same dimensions as the collision shape
        # then check if a point is inside the rect
        var rect = Rect2(collision.global_position - shape.extents, shape.extents * 2)
        if rect.has_point(pos):
            return room

    return null

# Attempt to find a room at a body's position.
# (overlaps_body() doesn't react very well to sudden position changes?)
func get_room_at_node(node):
    # use point check function
    return get_room_at_point(node.global_position)

    # if node is PhysicsBody2D:
    #     # use the builtin overlap function
    #     for room in get_rooms():
    #         if room.overlaps_body(node):
    #             return room
    #     return null
    # else:
    #     # use point check function
    #     return get_room_at_point(node.global_position)

func on_room_entered(room, player):
    print("[game] new room entered %s" % room)
    set_current_room(room)

func on_level_clear():
    print("[game] level cleared!")
    var tween = Util.new_tween(self)

    #var pitch_effect = AudioServer.get_bus_effect(0, 0)
    #tween.interpolate_property(Engine, "time_scale", 0.2, 1, 1)
    #tween.interpolate_method(pitch_effect, "set_pitch_scale", 0.8, 1.0, 0.5)
    #tween.start()
    # HUD.blink(0.5)
    Effects.play(Effects.Clear, get_player())

    yield(tween, "tween_all_completed")

    tween.queue_free()

func on_player_death():
    if not time_paused:
        num_deaths += 1

func debug_log(s):
    var file = File.new()
    file.open("res://log.txt", file.READ_WRITE)
    file.seek_end()
    file.store_line(s)

func get_camera() -> Node:
    return $"/root/main/camera"

func set_camera_focus(node):
    get_camera().set_target(node.get_path())

func get_enemies(parent = null):
    var enemies
    if parent == null:
        # get all enemies
        enemies = get_tree().get_nodes_in_group("enemy")
    else:
        # get enemies that are children of a node
        enemies = []
        for enemy in get_tree().get_nodes_in_group("enemy"):
            if enemy.get_parent() == parent:
                enemies.append(enemy)
    return enemies

func get_alive_enemies(parent = null):
    var enemies = []
    for enemy in get_enemies(parent):
        if enemy.health > 0:
            enemies.append(enemy)
    return enemies

func reset_enemies():
    for enemy in get_enemies():
        enemy.reset()

# Reset entities in the level (doors, etc.)
func reset_entities():
    for door in get_tree().get_nodes_in_group("door"):
        door.close_door(false)

func get_player() -> Node:
    return get_node_or_null("/root/main/player")

func get_debug_hud() -> Node:
    return $"/root/main/debug"

func _physics_process(delta):

    if not time_paused and not is_paused():
        time += delta

    if len(get_enemies()) > 0 and len(get_alive_enemies()) == 0 and not time_paused:
        stop_timer()

    var velocity = get_player().velocity
    var state_name = get_player().fsm.current_type
    HUD.get_node("debug/info").text = "speed: %3.2f (x=%3.2f, y=%3.2f)\nstate: %s" % [velocity.length(), velocity.x, velocity.y, state_name]

func _process(delta):

    # load hub world
    if Input.is_action_just_pressed("debug_level1"):
        load_scene(Level_TestHub)

    if Input.is_action_just_pressed("toggle_fullscreen"):
        OS.window_fullscreen = !OS.window_fullscreen

    # toggle "practice mode" which:
    # (1) the player will be able to hit dead enemies
    # (2) dead enemies will now be visible
    if Input.is_action_just_pressed("toggle_practice_mode"):
        practice_mode = !practice_mode
        debug_ping("Practice Mode: %s" % [practice_mode])

        if practice_mode:
            get_player().ignore_enemy_hp = true
            for enemy in get_tree().get_nodes_in_group("enemy"):
                enemy.is_visible_when_dead = true
                enemy.update_color()
        else:
            get_player().ignore_enemy_hp = false
            for enemy in get_tree().get_nodes_in_group("enemy"):
                enemy.is_visible_when_dead = false
                enemy.update_color()
                
    # toggle additional debug HUD info
    if Input.is_action_just_pressed("toggle_debug"):
        toggle_debug_mode()

    # pause menu
    if Input.is_action_just_pressed("pause"):
        if menu.visible:
            menu.hide()
        else:
            menu.show()

# Switch between different debug modes.
# Emits the "debug_mode_changed" signal.
#
func toggle_debug_mode() -> void:
    debug_mode = (debug_mode + 1) % len(DebugMode)
    emit_signal("debug_mode_changed", debug_mode)
        
# func _input(event):
    
     # used for me to identify what ID a button is
#    if event is InputEventJoypadButton:
#       print(event.button_index)

# Speedrun Timer
# ========================================================================

func is_best_time():
    return time_paused and time <= time_best

# Pause the ingame timer
func pause_timer():
    time_paused = true

func stop_timer():
    print("[timer] timer stopped")
    emit_signal("level_cleared")
    pause_timer()

    # calculate time difference
    HUD.set_diff_time(time, time_best)

    # check for new best time
    if is_best_time():
        print("[timer] new best time recorded")
        time_best = time
        HUD.set_best_time(time_best)
        # create a new ghost replay
        replay_manager.save_recording()

# Reset the ingame timer
func reset_timer():
    time = 0.0
    time_paused = false
    HUD.set_best_time(time_best)

func clear_best_times():
    time_best = INF
    HUD.reset_best_time()

# Palettes / Post Processing
# ========================================================================

func get_display_manager():
    return $"/root/main/post_process"

# Start Point / Checkpoints
# ========================================================================

# Gets the start point of the current level.
# This is where the player spawns when the level loads.
func get_start_point(idx = 0) -> Vector2:
    return get_level().get_start_point(idx)
    
# Text Box
# ========================================================================
func show_textbox(text):
    var textbox = Textbox.instance()
    textbox.set_text(text)
    HUD.add_child(textbox)
    HUD.move_child(textbox, 0)
    # textbox.load_text(texts)
    return textbox

func draw_text(node, text):
    spritefont.draw_text(node, text)

# Pausing and Screen Transitions
# ========================================================================

# Sets the time scale of the physics.
func set_time_scale(scale):
    Engine.time_scale = scale

func pause_and_fade_out(time):
    pause(self)
    yield(HUD.fade_out(time), "completed")

func fade_in_and_unpause(time):
    yield(HUD.fade_in(time), "completed")
    unpause(self)

func pause_and_lbox_in(time):
    pause(self)
    yield(HUD.lbox_in(time), "completed")

func unpause_and_lbox_out(time):
    unpause(self)
    yield(HUD.lbox_out(time), "completed")

# Call the given method on an object in the middle of a paused
# fade in/out transition.
func call_with_fade_transition(object, method, args = [], fade_out = 0.2, fade_in = 0.2):
    yield(pause_and_fade_out(fade_out), "completed")
    object.callv(method, args)
    yield(fade_in_and_unpause(fade_in), "completed")

func pause(node):
    # print("[game] %s wants to pause" % node.name)
    if not node in game_pause_requests:
        game_pause_requests.append(node)

        if len(game_pause_requests) == 1:
            emit_signal("paused")
            #print("paused")

func unpause(node):
    # print("[game] %s wants to unpause" % node.name)
    game_pause_requests.erase(node)
    if len(game_pause_requests) == 0:
        emit_signal("unpaused")
        #print("unpaused")

func is_paused():
    return len(game_pause_requests) > 0

# Debug functions
#===============================================================================

# Briefly show a message in the debug HUD.
func debug_ping(message):
    var pingtext = HUD.get_node("debug/pingtext")
    pingtext.text = message
    var tween = Tween.new()
    add_child(tween)
    tween.interpolate_property(pingtext, "modulate:a",
        1.0, 0.0, 1.0)
    tween.start()
    yield(tween, "tween_completed")
    remove_child(tween)


