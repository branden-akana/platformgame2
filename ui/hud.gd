#===============================================================================
# GameState HUD
#
# Contains scripting for the game HUD, such as timers, tooltips, etc.
# This script also contains:
# - controls for the color palette used by the levels
# - controls for transitions such as fade in/out and letterboxing
#===============================================================================

class_name HUD extends CanvasLayer

signal fade_in_finished
signal fade_out_finished

var fps_timer: Timer

var state_history = []
const MAX_STATES = 20

var tween: Tween

func _ready():

	tween = create_tween()
	tween.stop()
	# tween.process_mode = PROCESS_MODE_ALWAYS

	fps_timer = Timer.new()
	fps_timer.one_shot = false
	add_child(fps_timer)
	fps_timer.start(1.0)
	
	fps_timer.connect("timeout",Callable(self,"update_fps"))

	await GameState.get_player().ready

	GameState.get_player().action_performed.connect(on_state_changed)
	GameState.debug_mode_changed.connect(on_debug_mode_changed)

func toggle_visible():
	if layer == 5:
		layer = -1
	else:
		layer = 5

func on_debug_mode_changed(debug_mode: int) -> void:
	match debug_mode:
		# GameState.DebugMode.NORMAL:
		0:
			# $control.visible = true
			$debug.visible = false
		# GameState.DebugMode.DEBUG:
		1:
			# $control.visible = true
			$debug.visible = true

func hide():
	scale = Vector2.ZERO
	$ui_timer.visible = false

func show():
	scale = Vector2.ONE
	$ui_timer.visible = true

# Set the value of the HUD timer.
func set_timer(time):
	var m = floor(time / 60.0)          # minutes
	var s = floor(fmod(time, 60.0))    # seconds
	var ms = fmod(time, 1.0) * 1000     # milliseconds
	$ui_timer.set_time(m, s, ms)

func set_best_time(time: float) -> void:
	$ui_timer.set_best_time(time)

func set_diff_time(time: float, prev_best: float = INF) -> void:
	$ui_timer.set_diff_time(time, prev_best)

func reset_best_time() -> void:
	$ui_timer.reset_best_time()

# Set the value of the HUD death counter.
func set_deaths(num):
	# HUD.get_node("control/enemy_display").text = "enemies: %d" % len(get_alive_enemies())
	$ui_timer/death_display.text = "deaths %d" % num

# Briefly flash the screen white.
func blink(time):
	tween.stop()
	$white_fade.color.a = 0.1
	tween.tween_property($white_fade, "color:a", 0.0, time)
	
##
# Play the screen fade-in animation.
##
func fade_in(time):
	var tween = create_tween()
	$fade.color = Color(0.0, 0.0, 0.0, 1.0)

	tween.tween_property($fade, "color",
		Color(0.0, 0.0, 0.0, 0.0),
		time).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	
	await tween.finished
	emit_signal("fade_in_finished")

##
# Play the screen fade-out animation.
##
func fade_out(time):
	var tween = create_tween()
	$fade.color.a = 0

	tween.tween_property($fade, "color:a", 1,
		time).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	
	await tween.finished
	emit_signal("fade_out_finished")

func lbox_in(time):
	tween.stop()
	$letterbox1.color.a = 0
	$letterbox2.color.a = 0
	$letterbox1.position.y = -128
	$letterbox2.position.y = 590 + 128
	tween.tween_property($letterbox1, "color:a", 1,
		time).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property($letterbox2, "color:a", 1,
		time).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property($letterbox1, "position:y",
		0,
		time).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property($letterbox2, "position:y",
		590,
		time).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	
	await tween.finished

func lbox_out(time):
	tween.stop()
	$letterbox1.position.y = 0
	$letterbox2.position.y = 590

	tween.tween_property($letterbox1, "position:y",
		-128,
		time).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property($letterbox2, "position:y",
		590 + 128,
		time).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)

	await tween.finished

func area_title_in(title, time):
	var tween = create_tween().set_parallel(true)
	$area_title/label.text = title
	$area_title.modulate.a = 0
	$area_title.position.y = 620 + 128

	tween.tween_property($area_title, "modulate:a", 1, time)
	tween.tween_property($area_title, "position:y", 620, time)

	await tween.finished

func area_title_out(time):
	var tween = create_tween().set_parallel(true)
	$area_title.modulate.a = 1
	$area_title.position.y = 620

	tween.tween_property($area_title, "modulate:a", 0, time)
	tween.tween_property($area_title, "position:y", 620 + 128, time)

	await tween.finished


func update_fps():
	$debug/BL/fps.text = str(Engine.get_frames_per_second())


func on_state_changed(action):
	state_history.insert(0, action)
	if len(state_history) > MAX_STATES: state_history.pop_back()
	$debug/state_display/current_state.text = state_history[0]
	if len(state_history) > 1:
		$debug/state_display/past_states.text = "\n".join(state_history.slice(1, len(state_history) - 1))

func _process(_delta):
	
	offset = lerp(offset, -GameState.get_player().velocity * 0.02, 0.25)
	# offset = lerp(offset, -GameState.get_camera().velocity * 10, 0.05)

func _physics_process(_delta):

	$debug/TL/pos_x.text = "%+08.2f" % GameState.get_player().global_position.x
	$debug/TL/pos_y.text = "%+08.2f" % GameState.get_player().global_position.y
	$debug/TL/vel_x.text = "%+08.2f" % GameState.get_player().velocity.x
	$debug/TL/vel_y.text = "%+08.2f" % GameState.get_player().velocity.y
	$debug/TL/speed.text = "%04d" % GameState.get_player().velocity.length()
	$debug/TL/grounded.text = "%s" % GameState.get_player().is_grounded

	var cam: GameCamera = GameState.get_camera()
	var room: LevelScreen = GameState.get_current_level().get_current_room()

	$debug/BL/cam.text = str(cam.focus.round())
	$debug/BL/cam_pre.text = str(cam.pre_cam_pos.round())
	$debug/BL/cam_bounds.text = "%s -> %s" % [cam.min_position, cam.max_position]
	$debug/BL/cam_tracking.text = "%s" % [cam.get_tracking_position()]

	if room:
		$debug/BL/room.text = "%s" % [room.get_name()]
	else:
		$debug/BL/room.text = "----"
	$debug/BL/tick.text = str(GameState.get_player().tick)

	var ecb = GameState.get_player()._ecb
	var checked = Color(1, 1, 1, 1.0)
	var unchecked = Color(1, 1, 1, 0.5)

	$debug/ray_l.color = checked if ecb.left_collide_out() else unchecked
	$debug/ray_r.color = checked if ecb.right_collide_out() else unchecked
	$debug/ray_u.color = checked if ecb.top_collide_out() else unchecked
	$debug/ray_d.color = checked if ecb.bottom_collide_out() else unchecked
	
	
