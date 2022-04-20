extends Node2D

signal paused
signal unpaused
signal level_restarted
signal level_cleared
signal scene_loaded

const Textbox = preload("res://scenes/textbox.tscn")

const Level_TestHub = preload("res://scenes/levels/test_hub.tscn")

const GhostPlayer = preload("res://scenes/ghost_player.tscn")

var frame: int = 0

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

# amount of time user has held pause
var pause_hold_time = 0.0

# the current level that is loaded
onready var current_level = get_level()

# the current room that the player is in
var current_room = null setget set_current_room

# used to draw sprite text
onready var spritefont = SpriteTextRenderer.new()

# flags
var practice_mode = false
var is_recording = true   # if true, record the player
var replay = null         # ref to the last saved replay
var replay_ghost = null   # ref to the ghost that plays replays

func _ready():

    add_child(spritefont)

    # Game initialization stuff

    # hide debug hud
    get_debug_hud().scale = Vector2.ZERO

    Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

    print("Feel free to minimize this window! It needs to be open for some reason to avoid a crash.")

    get_player().connect("died", self, "on_player_death")
    connect("level_cleared", self, "on_level_clear")
    
    yield(get_player(), "ready")

    reinitialize_game()

# Initialize the game. Use after loading a new level.
func reinitialize_game():

    frame = 0

    # reset best time / ghost
    clear_best_times()
    replay_clear()

    restart_player()
    restart_level()
    
# Restart the level. Use to reset the state of just the level.
func restart_level():

    # stop replay recording
    replay_stop_recording()

    # reset stats / timers
    num_deaths = 0
    reset_timer()

    # reset state of the level
    reset_enemies()
    reset_entities()

    # reset camera
    get_camera().init()

    # start replay recording and playback
    replay_start_recording()
    replay_playback_start()
    
    # reparent objects to respective canvaslayers
    reparent_all()

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

    # debug_log("clearing children")
    
    # clear all objects in other viewports
    clear_fg2()
    clear_fg3()

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

func set_current_room(room):
    # print("entered new room")
    current_room = room

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
    get_camera().set_room_focus(room)

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
    return $"/root/main/player"

func get_debug_hud() -> Node:
    return $"/root/main/debug"

func _physics_process(delta):

    if not time_paused and not is_paused():
        time += delta

    if len(get_enemies()) > 0 and len(get_alive_enemies()) == 0 and not time_paused:
        stop_timer()

    # update HUD timer
    HUD.get_node("control/timer").text = "%02d:%02d" % [floor(time/60.0), floor(fmod(time, 60.0))]
    HUD.get_node("control/timer_small").text = "%03d" % [fmod(time, 1.0) * 1000]
    # HUD.get_node("control/enemy_display").text = "enemies: %d" % len(get_alive_enemies())
    HUD.get_node("control/death_display").text = "deaths %d" % num_deaths

    var velocity = get_player().velocity
    var state_name = get_player().sm.current_type
    get_node("/root/main/debug/info").text = "speed: %3.2f (x=%3.2f, y=%3.2f)\nstate: %s" % [velocity.length(), velocity.x, velocity.y, state_name]

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
        var hud = get_debug_hud()
        var info = hud.get_node("info")
        if hud.scale == Vector2.ONE and not info.visible:
            info.visible = true
        elif hud.scale == Vector2.ONE and info.visible:
            info.visible = false
            hud.scale = Vector2.ZERO
        else:
            hud.scale = Vector2.ONE


    # hold to quit
    if Input.is_action_pressed("pause"):
        if pause_hold_time == 0:
            debug_ping("Hold to quit")
        pause_hold_time += delta
        if pause_hold_time > 1.0:
            get_tree().quit()
    else:
        pause_hold_time = 0

        
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
    if time_best < INF:
        HUD.get_node("control/best_diff").text = Util.format_time_diff(time - time_best)

    # check for new best time
    if is_best_time():
        print("[timer] new best time recorded")
        time_best = time
        # create a new ghost replay
        replay_save()

# Reset the ingame timer
func reset_timer():
    time = 0.0
    time_paused = false
    HUD.get_node("control/best_diff").text = ""
    if time_best < INF:
        HUD.get_node("control/best").text = "best %s" % Util.format_time(time_best)

func clear_best_times():
    time_best = INF
    HUD.get_node("control/best").text = ""

# Palettes / Viewports
# ========================================================================

# Foreground 1: used by the player
func get_fg1():
    return $"/root/main/post_process/fg1/container/viewport"

func get_fg1_container() -> ViewportContainer:
    return $"/root/main/post_process/fg1/container" as ViewportContainer

# Foreground 2: used for enemies
func get_fg2():
    return $"/root/main/post_process/fg2/container/viewport"

func get_fg2_container() -> ViewportContainer:
    return $"/root/main/post_process/fg2/container" as ViewportContainer

# Free all the children in foreground layer 2.
func clear_fg2():
    for child in get_fg2().get_children():
        get_fg2().remove_child(child)
        child.queue_free()

# Foreground 3: ???
func get_fg3():
    return $"/root/main/post_process/fg3/container/viewport"

func get_fg3_container() -> ViewportContainer:
    return $"/root/main/post_process/fg3/container" as ViewportContainer

# Free all the children in foreground layer 2.
func clear_fg3():
    for child in get_fg3().get_children():
        get_fg3().remove_child(child)
        child.queue_free()
    
func reparent_to_viewport(node, viewport):

    if not node: return  # ignore null nodes
    if node.get_parent() == viewport: return

    var copy = node
    if node is TileMap:
        # create a copy instead of reparenting to retain collisions
        copy = node.duplicate()
        node.modulate = Color(0, 0, 0, 0)
        copy.visible = true

    if copy.get_parent():
        copy.get_parent().call_deferred("remove_child", copy)
        yield(get_tree(), "idle_frame")
    
    # shift copy to fix sub-pixels
    copy.position = node.global_position + Vector2(2, -2)
    copy.set_as_toplevel(true)
    viewport.add_child(copy)


# Reparent this node to FG1. Note that this node's position must now be handled manually.
func reparent_to_fg1(node):
    reparent_to_viewport(node, get_fg1())


# Reparent this node to FG2. Note that this node's position must now be handled manually.
func reparent_to_fg2(node):
    reparent_to_viewport(node, get_fg2())


func reparent_to_fg3(node):
    reparent_to_viewport(node, get_fg3())

func reparent_all():
    for node in get_tree().get_nodes_in_group("LAYER_FG1"):
        reparent_to_fg1(node)

    for node in get_tree().get_nodes_in_group("LAYER_FG2"):
        reparent_to_fg2(node)

    for node in get_tree().get_nodes_in_group("LAYER_FG3"):
        reparent_to_fg3(node)

func get_post_processor():
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

# Replay / Ghost functions
#===============================================================================

# Start recording a replay.
func replay_start_recording():
    get_player().clear_recorded_data()
    is_recording = true
    print("[demo] recording started")
    debug_ping("recording started")

# Stop recording a replay.
func replay_stop_recording():
    is_recording = false
    print("[demo] recording stopped")
    debug_ping("recording stopped")

func replay_save():
    replay = get_player().export_replay()
    print("[demo] new replay saved! (%d frames)" % len(replay.input_frames))
    print("    position: %s" % replay.start_position)
    print("    velocity: %s" % replay.start_velocity)
    print("    state: %s" % replay.start_state_type)
    debug_ping("recording saved")

# Start playback of the last replay (using a ghost).
func replay_playback_start():
    if is_instance_valid(replay):
        print("[demo] playback started")

        if not is_instance_valid(replay_ghost):
            print("[ghost] creating new ghost")
            replay_ghost = GhostPlayer.instance()
            $"/root/main".add_child(replay_ghost)

        replay_ghost.load_replay(replay)
        replay_ghost.restart()
    else:
        print("[demo] no replay to playback!")

func replay_playback_stop():
    print("[demo] playback stopped")
    if is_instance_valid(replay_ghost):
        replay_ghost.stop()

# Stop playback.
func replay_clear():
    print("[demo] recording cleared")
    replay = null
    if is_instance_valid(replay_ghost):
        print("[ghost] deleting ghost")
        replay_ghost.queue_free()



# Debug functions
#===============================================================================

# Briefly show a message in the debug HUD.
func debug_ping(message):
    var pingtext = get_debug_hud().get_node("pingtext")
    pingtext.text = message
    var tween = Tween.new()
    add_child(tween)
    tween.interpolate_property(pingtext, "modulate:a",
        1.0, 0.0, 1.0)
    tween.start()
    yield(tween, "tween_completed")
    remove_child(tween)


