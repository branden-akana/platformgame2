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

onready var tween: Tween

func _ready():
    tween = Tween.new()
    tween.pause_mode = PAUSE_MODE_PROCESS
    add_child(tween)

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

func _physics_process(delta):
    set_timer(Game.time)
    set_deaths(Game.num_deaths)

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
    var tween = Util.new_tween(self)
    $"area_title/label".text = title
    tween.interpolate_property($"area_title", "modulate:a", 0, 1, time)
    tween.interpolate_property($"area_title", "rect_position:y", 620 + 128, 620, time)
    tween.start()
    Util.await_tween(tween)

func area_title_out(time):
    var tween = Util.new_tween(self)
    tween.interpolate_property($"area_title", "modulate:a", 1, 0, time)
    tween.interpolate_property($"area_title", "rect_position:y", 620, 620 + 128, time)
    tween.start()
    Util.await_tween(tween)
