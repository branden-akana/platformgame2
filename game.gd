extends Node2D


signal paused
signal unpaused
signal level_restarted
signal level_cleared
signal scene_loaded
signal post_ready
signal debug_mode_changed
signal practice_mode_changed


const Textbox = preload("res://ui/textbox.tscn")


# list of pause reasons
enum PauseRequester {
	SCREEN_CHANGE,  # used during screen transitions
	MENU            # used for when player enters menu
}

enum DebugMode {NORMAL, DEBUG, HITBOXES}


# path to the active player
@export_node_path(Character) var player: NodePath = NodePath("/root/main/player")

# path to the HUD
@export_node_path(HUD) var hud: NodePath = NodePath("/root/main/hud")

# path to the currently loaded level
@export_node_path(Level) var current_level: NodePath = NodePath("/root/main/level")

# path to the active room
@export_node_path(Node) var current_room: NodePath

# path to the vfx manager
@export_node_path(VFXManager) var vfx_manager = NodePath("/root/main/post_process")

# path to the active camera
@export_node_path(GameCamera) var camera = NodePath("/root/main/camera")

# currently loaded settings
@export var settings: UserSettings

## if true, remove_at control from the player
@export var is_in_menu: bool = false    

# flags
@export var is_practice_mode_enabled: bool = false


# total ticks for the currently loaded level
var tick: int = 0
# game pausing variables
var game_pause_requests = []  # contains refs to nodes that want to pause the game

# amount of time user has held pause
var pause_hold_time = 0.0

var debug_mode: int = DebugMode.NORMAL


@onready var run_timer: GameTimer = GameTimer.new(self)

# used to draw sprite text
@onready var spritefont = SpriteLabel.new()

var menu


func _ready():

	print("READYING GAME")

	# UserSettings load
	# settings = UserSettings.load_settings()
	
	add_child(spritefont)

	# GameState initialization stuff
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	get_tree().set_auto_accept_quit(false)

	# print("Feel free to minimize this window! It needs to be open for some reason to avoid a crash.")
	
	# initialize menu
	menu = get_hud().get_node("main_menu")

	# initialize player
	var player: PlayerCharacter = get_player()
	# if $"/root/main".has_node("player"):  # try to find a player
	# 	player = get_player()  
	# else:  # or manually spawn the player
	# 	player = PlayerCharacter.instantiate()
	# 	$"/root/main".add_child(player)

	player.connect("died", run_timer.on_player_death)
	await player.ready

	run_timer.connect("run_complete", on_level_clear)

	reinitialize_game()
	
	# wait for editor nodes to free
	# await free_editor_nodes()
	
	# initialize post process manager
	#var pp = DisplayManager.instantiate()
	#$"/root/main".add_child(pp)

	print("GAMESTATE IS READY!")
	post_ready.emit()

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		exit()
	
func free_editor_nodes():
	# remove_at all "editor only" nodes
	for node in get_tree().get_nodes_in_group("editor_only"):
		await node.tree_exiting


func get_player() -> Character:
	# var player = %player as PlayerCharacter
	var player = get_node(self.player) as PlayerCharacter
	assert(player != null, "Unable to get player")
	return player
	# return get_node(player)


func get_hud() -> HUD:
	return get_node(self.hud) as HUD


func get_current_level() -> Level:
	return get_node(current_level)


# Gets n start point of the current level.
func get_start_point(n: int = 0) -> Vector2:
	return get_current_level().get_start_point(n)

##
## Get the room in focus in the current level.
##
func get_current_room() -> Node:
	return get_node(current_room)

##
## Get all rooms in the current level.
##
func get_all_rooms() -> Array:
	return get_tree().get_nodes_in_group("room")


func get_display() -> VFXManager:
	return get_node(vfx_manager)


func get_camera() -> GameCamera:
	return get_node(camera)


# Initialize the game. Use after loading a new level.
func reinitialize_game():
	print("REINIITALIZING GAME!")
	tick = 0

	# reset best time / ghost
	run_timer.clear_best_times()

	var level = get_node(current_level)
	if settings and run_timer.has_record(level.level_name):
		run_timer.time_best = settings.records[level.level_name]

	restart_player()
	#restart_level()
		
	
# Restart the level. Use to reset the state of just the level.
func restart_level():
	print_debug("RESTARTING LEVEL!")

	# reset the run timer
	run_timer.reset_run()

	# reset state of the level
	reset_enemies()
	reset_entities()

	# reset camera
	get_camera().init()

	# start the run timer
	run_timer.start_run()
	
	emit_signal("level_restarted")

# Restart the current room.
func restart_room():
	var room = get_node_or_null(current_room)
	if room:
		room.reset_room()

func restart_player():
	print("RESTARTING PLAYER!")
	# set start position
	get_player().restart()

func load_scene(level):
	# debug_log("loading new scene...")
	# debug_log("fading out...")
	await pause_and_fade_out(0.5)
	call_deferred("_load_scene", level)
	# await self.scene_loaded
	# debug_log("fading in...")
	await fade_in_and_unpause(0.5)
	# debug_log("finished!")

func _load_scene(level_path):

	# debug_log("loading new scene")

	# load the new scene
	var level: Level = level_path.instantiate()
	level.name = "level"

	# remove_at current scene and add new one
	# debug_log("removing old scene")

	get_node(current_level).free()

	# debug_log("adding new scene as child")

	$"/root/main".add_child(level)
	current_level = level.get_path()

	# debug_log("restarting level...")

	# reinit the game
	reinitialize_game()

	# debug_log("new scene loaded")

	emit_signal("scene_loaded")

# Level/Node3D Functions
# ========================================================================

# Sets the current room to focus checked.
#
# The camera will now be bound within this room.
# If smooth_transition is true, briefly pause the game and transition
# the camera to the new room. Otherwise, move the camera to the
# new room instantly.
func set_current_room(room: RoomZone, do_transition: bool = true):
	# print("entered new room")
	# NOOP if screen is invalid or is already current screen
	if room == null or current_room == room.get_path(): return
	current_room = room.get_path()

	# lock camera to this screen area
	var bounds = room.get_bounds()
	get_camera().set_bounds(bounds[0], bounds[1], do_transition, room.palette_idx)


# Attempt to find a room at this position. If none is found, return null.
func get_room_at_point(pos):
	# print("finding %s in %s" % [pos, get_rooms()])
	for room in get_all_rooms():
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
	# var tween = create_tween()

	#var pitch_effect = AudioServer.get_bus_effect(0, 0)
	#tween.tween_property(Engine, "time_scale", 0.2, 1, 1)
	#tween.interpolate_method(pitch_effect, "set_pitch_scale", 0.8, 1.0, 0.5)
	#tween.start()
	# HUD.blink(0.5)
	Effects.play(Effects.Clear, get_player())

	# await tween.tween_all_completed

	# tween.queue_free()

func debug_log(s):
	var file = FileAccess.open("res://log.txt", FileAccess.READ_WRITE)
	file.seek_end()
	file.store_line(s)

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


func get_debug_hud() -> Node:
	return $"/root/main/debug"


func _physics_process(delta):

	run_timer.process(delta)

	var velocity = get_player().velocity
	var state_name = get_player().fsm.current_type
	get_hud().get_node("debug/info").text = "speed: %3.2f (x=%3.2f, y=%3.2f)\nstate: %s" % [velocity.length(), velocity.x, velocity.y, state_name]


func _process(delta):

	# print("game_process")

	if Input.is_action_just_pressed("toggle_fullscreen"):
		if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

	# toggle "practice mode" which:
	# (1) the player will be able to hit dead enemies
	# (2) dead enemies will now be visible
	# if Input.is_action_just_pressed("toggle_practice_mode"):
	# 	toggle_practice_mode()
				
	# toggle additional debug HUD info
	if Input.is_action_just_pressed("toggle_debug"):
		toggle_debug_mode()

	# pause menu
	if Input.is_action_just_pressed("pause"):
		if menu.visible:
			menu.menu_hide()
		else:
			menu.menu_show()

# Toggle practice mode.
# Emits the "practice_mode_changed" signal.
#
func toggle_practice_mode() -> void:
	is_practice_mode_enabled = !is_practice_mode_enabled
	debug_ping("Practice Mode: %s" % [is_practice_mode_enabled])

	if is_practice_mode_enabled:
		get_player().ignore_enemy_hp = true
		for enemy in get_tree().get_nodes_in_group("enemy"):
			enemy.is_visible_when_dead = true
			enemy.update_color()
	else:
		get_player().ignore_enemy_hp = false
		for enemy in get_tree().get_nodes_in_group("enemy"):
			enemy.is_visible_when_dead = false
			enemy.update_color()

	get_player().player_restart()
	emit_signal("practice_mode_changed", is_practice_mode_enabled)

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


# Text Box
# ========================================================================
func show_textbox(text):
	var textbox = Textbox.instantiate()
	textbox.set_text(text)
	get_hud().add_child(textbox)
	get_hud().move_child(textbox, 0)
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
	await get_hud().fade_out(time)

func fade_in_and_unpause(time):
	await get_hud().fade_in(time)
	unpause(self)

func pause_and_lbox_in(time):
	pause(self)
	await get_hud().lbox_in(time)

func unpause_and_lbox_out(time):
	unpause(self)
	await get_hud().lbox_out(time)

# Call the given method checked an object in the middle of a paused
# fade in/out transition.
func call_with_fade_transition(object, method, args = [], fade_out = 0.2, fade_in = 0.2):
	await pause_and_fade_out(fade_out)
	object.callv(method, args)
	await fade_in_and_unpause(fade_in)

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
	var pingtext = get_hud().get_node("debug/pingtext")
	pingtext.text = message

	var tween = create_tween()
	pingtext.modulate.a = 1.0
	tween.tween_property(pingtext, "modulate:a",
		0.0, 1.0)


func exit() -> void:
	print("exiting game")
	if settings: settings.save()
	get_tree().quit()

