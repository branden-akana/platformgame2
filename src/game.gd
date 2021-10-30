extends Node2D

signal paused
signal unpaused
signal scene_loaded

const Textbox = preload("res://scenes/textbox.tscn")

var time: float = 0.0
var time_best: float = INF
var time_paused: bool = false

var game_pause_requests = []
var game_paused: bool setget , is_game_paused

onready var current_scene = $"/root/Main/World"

# Engine.time_scale = 0.5
func _ready():
    # var Player = load("res://scenes/player.tscn")
    # var plr = Player.instance()
    # $"/root/Main".add_child(plr)
    restart_level()
    
# Initialize the level. Use after loading a new level
func restart_level():

    # set start position
    get_player().restart()
    reset_timer()
    reset_enemies()
    get_camera().init()

func load_scene(path):
    yield(pause_and_fade_out(0.5), "completed")
    call_deferred("_load_scene", path)
    yield(self, "scene_loaded")
    yield(fade_in_and_unpause(0.5), "completed")

func _load_scene(path):
    # remove current scene
    get_current_scene().free()

    # also clear all objects in other viewports
    for child in get_fg2().get_children():
        child.queue_free()

    # load the new scene
    var s = ResourceLoader.load(path)
    current_scene = s.instance()
    current_scene.name = "World"
    $"/root/Main".add_child(current_scene)

    # reset the level
    restart_level()

    emit_signal("scene_loaded")

func get_current_scene():
    return $"/root/Main/World"

func get_current_level() -> Level:
    return $"/root/Main/World/level" as Level

func get_camera() -> Node:
    return $"/root/Main/camera"

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

func get_player() -> Node:
    return $"/root/Main/player"

func _physics_process(delta):
    if not time_paused and not game_paused:
        time += delta

    if len(get_alive_enemies()) == 0 and not time_paused:
        pause_timer()

    if Input.is_action_just_pressed("debug_level1"):
        load_scene("res://scenes/Level_Test2.tscn")

    if Input.is_action_just_pressed("debug_level2"):
        load_scene("res://scenes/Level_Test.tscn")

    # update HUD timer
    HUD.get_node("control/timer").text = "%02d:%05.2f" % [floor(time/60.0), fmod(time, 60.0)]
    HUD.get_node("control/enemy_display").text = "enemies: %d" % len(get_alive_enemies())

func is_best_time():
    return time_paused and time < time_best

# Pause the ingame timer
func pause_timer():
    time_paused = true

# Reset the ingame timer
func reset_timer():
    if is_best_time():
        time_best = time
    time = 0.0
    time_paused = false

# Palettes / Viewports
# ========================================================================

func get_foreground() -> Viewport:
    return $"/root/Main/viewports/fg/viewport" as Viewport

func get_foreground_container() -> ViewportContainer:
    return $"/root/Main/viewports/fg" as ViewportContainer

func get_fg2() -> Viewport:
    return $"/root/Main/viewports/fg2/viewport" as Viewport

func get_fg2_container() -> ViewportContainer:
    return $"/root/World/viewports/fg2" as ViewportContainer
    
# Reparent this node to FG1. Note that this node's position must now be handled manually.
func reparent_to_fg1(node):

    node.get_parent().remove_child(node)
    node.set_as_toplevel(true)
    get_foreground().add_child(node)
    
# Reparent this node to FG2. Note that this node's position must now be handled manually.
func reparent_to_fg2(node):

    node.get_parent().remove_child(node)
    node.set_as_toplevel(true)
    get_fg2().add_child(node)
    

# Start Point / Checkpoints
# ========================================================================

var start_point_idx = 0

func get_start_point() -> Node2D:
    var key
    if start_point_idx == 0:
        key = "/root/Main/World/spawns/start"
    else:
        key = "/root/Main/World/spawns/start%d" % start_point_idx
    return get_node(key) as Node2D

func set_start_point(idx):
    start_point_idx = idx
    
# Text Box
# ========================================================================

func show_textbox(text):
    var textbox = Textbox.instance()
    textbox.set_text(text)
    HUD.add_child(textbox)
    HUD.move_child(textbox, 0)
    # textbox.load_text(texts)
    return textbox

# Pausing and Screen Transitions
# ========================================================================

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

func pause(node):
    if not node in game_pause_requests:
        game_pause_requests.append(node)

        if not is_game_paused() and len(game_pause_requests) == 1:
            emit_signal("paused")
            print("paused")

func unpause(node):
    game_pause_requests.erase(node)
    if is_game_paused() and len(game_pause_requests) == 0:
        emit_signal("unpaused")
        print("unpaused")

func is_game_paused():
    return len(game_pause_requests) > 0





