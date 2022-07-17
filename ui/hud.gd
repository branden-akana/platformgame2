#===============================================================================
# Game HUD
#
# Contains scripting for the game HUD, such as timers, tooltips, etc.
# This script also contains:
# - controls for the color palette used by the levels
# - controls for transitions such as fade in/out and letterboxing
#===============================================================================

extends CanvasLayer

signal fade_in_finished
signal fade_out_finished

var fps_timer: Timer

var state_history = []
const MAX_STATES = 20

onready var tween: Tween

func _ready():
    tween = Tween.new()
    tween.pause_mode = PAUSE_MODE_PROCESS
    add_child(tween)

    fps_timer = Timer.new()
    fps_timer.one_shot = false
    add_child(fps_timer)
    fps_timer.start(1.0)
    
    fps_timer.connect("timeout", self, "update_fps")

    yield(Game, "ready")

    Game.get_player().fsm.connect("state_changed", self, "on_state_changed")

    Game.connect("debug_mode_changed", self, "on_debug_mode_changed")

func toggle_visible():
    if layer == 5:
        layer = -1
    else:
        layer = 5

func on_debug_mode_changed(debug_mode: int) -> void:
    match debug_mode:
        Game.DebugMode.NORMAL:
            $control.visible = true
            $debug.visible = false
        Game.DebugMode.DEBUG:
            $control.visible = true
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
    $control/ui_timer.set_time(m, s, ms)

func set_best_time(time: float) -> void:
    $control/ui_timer.set_best_time(time)

func set_diff_time(time: float, prev_best: float = INF) -> void:
    $control/ui_timer.set_diff_time(time)

func reset_best_time() -> void:
    $control/ui_timer.reset_best_time()

# Set the value of the HUD death counter.
func set_deaths(num):
    # HUD.get_node("control/enemy_display").text = "enemies: %d" % len(get_alive_enemies())
    $"control/death_display".text = "deaths %d" % num

# Briefly flash the screen white.
func blink(time):
    tween.interpolate_property($white_fade, "color:a", 0.1, 0.0, time)
    tween.start()

# Play the screen fade-in animation.
func fade_in(time):
    tween.interpolate_property($fade, "color",
        Color(0.0, 0.0, 0.0, 1.0),
        Color(0.0, 0.0, 0.0, 0.0),
        time, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
    tween.start()
    yield(tween, "tween_all_completed")
    emit_signal("fade_in_finished")
    return tween

# Play the screen fade-out animation.
func fade_out(time):
    tween.interpolate_property($fade, "color:a", 0, 1,
        time, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
    tween.start()
    yield(tween, "tween_all_completed")
    emit_signal("fade_out_finished")
    return tween

func lbox_in(time):
    tween.reset_all()
    tween.interpolate_property($letterbox1, "color:a", 0, 1,
        time, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
    tween.interpolate_property($letterbox2, "color:a", 0, 1,
        time, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
    tween.interpolate_property($letterbox1, "position:y",
        -128,
        0,
        time, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
    tween.interpolate_property($letterbox2, "position:y",
        590 + 128,
        590,
        time, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
    tween.start()
    yield(tween, "tween_completed")

func lbox_out(time):
    tween.reset_all()
    tween.interpolate_property($letterbox1, "position:y",
        0,
        -128,
        time, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
    tween.interpolate_property($letterbox2, "position:y",
        590,
        590 + 128,
        time, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
    tween.start()
    yield(tween, "tween_completed")

func area_title_in(title, time):
    var tween = Util.create_tween(self)
    $"area_title/label".text = title
    tween.interpolate_property($"area_title", "modulate:a", 0, 1, time)
    tween.interpolate_property($"area_title", "rect_position:y", 620 + 128, 620, time)
    tween.start()
    Util.await_tween(tween)

func area_title_out(time):
    var tween = Util.create_tween(self)
    tween.interpolate_property($"area_title", "modulate:a", 1, 0, time)
    tween.interpolate_property($"area_title", "rect_position:y", 620, 620 + 128, time)
    tween.start()
    Util.await_tween(tween)


func update_fps():
    $debug/fps.text = "%d fps" % Engine.get_frames_per_second()

func on_state_changed(state_to, state_from):
    state_history.insert(0, state_to)
    if len(state_history) > MAX_STATES: state_history.pop_back()
    $debug/state_display/current_state.text = state_history[0]
    $debug/state_display/past_states.text = PoolStringArray(state_history.slice(1, len(state_history) - 1)).join("\n")

func _physics_process(delta):
    $debug/tick.text = Game.get_player().tick
    $debug/pos_x.text = round(Game.get_player().global_position.x)
    $debug/pos_y.text = round(Game.get_player().global_position.y)
    $debug/vel_x.text = round(Game.get_player().velocity.x)
    $debug/vel_y.text = round(Game.get_player().velocity.y)
    $debug/grounded.text = "grounded: %s" % Game.get_player().is_grounded()

    var ecb = Game.get_player().get_ecb()
    var on = Color(1, 1, 1, 1.0)
    var off = Color(1, 1, 1, 0.5)

    $debug/ray_l.color = on if ecb.left_collide_out() else off
    $debug/ray_r.color = on if ecb.right_collide_out() else off
    $debug/ray_u.color = on if ecb.top_collide_out() else off
    $debug/ray_d.color = on if ecb.bottom_collide_out() else off
    
    
