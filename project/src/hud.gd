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

func toggle_visible():
    if layer == 5:
        layer = -1
    else:
        layer = 5

func hide():
    layer = -1

func show():
    layer = 5

func blink(time):
    tween.interpolate_property($white_fade, "color:a", 0.1, 0.0, time)
    tween.start()

func fade_in(time):
    tween.interpolate_property($fade, "color",
        Color(0.0, 0.0, 0.0, 1.0),
        Color(0.0, 0.0, 0.0, 0.0),
        time, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
    tween.interpolate_property(Game.get_fg1_container(), "modulate:a", 0, 1,
        time, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
    tween.interpolate_property(Game.get_fg2_container(), "modulate:a", 0, 1,
        time, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
    tween.interpolate_property(Game.get_fg3_container(), "modulate:a", 0, 1,
        time, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
    tween.start()
    yield(tween, "tween_all_completed")
    emit_signal("fade_in_finished")
    return tween

func fade_out(time):
    tween.interpolate_property($fade, "color:a", 0, 1,
        time, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
    tween.interpolate_property(Game.get_fg1_container(), "modulate:a", 1, 0,
        time, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
    tween.interpolate_property(Game.get_fg2_container(), "modulate:a", 1, 0,
        time, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
    tween.interpolate_property(Game.get_fg3_container(), "modulate:a", 1, 0,
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
