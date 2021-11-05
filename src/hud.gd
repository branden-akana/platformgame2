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

export (Array, Texture) var palettes
var current_palette = 0

var shader: ColorRect

func _ready():
    tween = Tween.new()
    tween.pause_mode = PAUSE_MODE_PROCESS
    add_child(tween)
    
    shader = get_node("pixel_filter/post_processing")
    
func set_palette(idx):
    if idx < len(palettes):
        current_palette = idx
        shader.get_material().set_shader_param("palette_a", palettes[idx])
        
func set_palette_back(idx):
    if idx < len(palettes):
        shader.get_material().set_shader_param("palette_b", palettes[idx])
        
# 0.0 => palette A, 1.0 => palette B
func set_palette_blend(n):
    shader.get_material().set_shader_param("palette_blend", n)
    
func change_palette(idx, time = 0.5):
    if idx != current_palette:
        set_palette_back(current_palette)
        set_palette(idx)
        if time == 0:
            set_palette_blend(0.0)
            yield(get_tree(), "idle_frame")
        else:
            set_palette_blend(1.0)
            tween.interpolate_method(self, "set_palette_blend",
                1.0, 0.0,
                time, Tween.TRANS_LINEAR, Tween.EASE_OUT)
            tween.start()
            yield(tween, "tween_completed")
    else:
        yield(get_tree(), "idle_frame")

func blink(time):
    tween.interpolate_property($white_fade, "color:a", 0.1, 0.0, time)
    tween.start()

func fade_in(time):
    tween.interpolate_property($fade, "color",
        Color(0.0, 0.0, 0.0, 1.0),
        Color(0.0, 0.0, 0.0, 0.0),
        time, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
    tween.interpolate_property(Game.get_foreground_container(), "modulate",
        Color(1.0, 1.0, 1.0, 0.0),
        Color(1.0, 1.0, 1.0, 1.0),
        time, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
    tween.interpolate_property(Game.get_fg2_container(), "modulate",
        Color(1.0, 1.0, 1.0, 0.0),
        Color(1.0, 1.0, 1.0, 1.0),
        time, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
    tween.start()
    yield(tween, "tween_all_completed")
    emit_signal("fade_in_finished")
    return tween

func fade_out(time):
    tween.interpolate_property($fade, "color",
        Color(0.0, 0.0, 0.0, 0.0),
        Color(0.0, 0.0, 0.0, 1.0),
        time, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
    tween.interpolate_property(Game.get_foreground_container(), "modulate",
        Color(1.0, 1.0, 1.0, 1.0),
        Color(1.0, 1.0, 1.0, 0.0),
        time, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
    tween.interpolate_property(Game.get_fg2_container(), "modulate",
        Color(1.0, 1.0, 1.0, 1.0),
        Color(1.0, 1.0, 1.0, 0.0),
        time, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
    tween.start()
    yield(tween, "tween_all_completed")
    emit_signal("fade_out_finished")
    return tween

func lbox_in(time):
    $letterbox1.position.y = 0
    $letterbox2.position.y = 590
    tween.interpolate_property($letterbox1, "color",
        Color(0.0, 0.0, 0.0, 0.0),
        Color(0.0, 0.0, 0.0, 1.0),
        time, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
    tween.interpolate_property($letterbox2, "color",
        Color(0.0, 0.0, 0.0, 0.0),
        Color(0.0, 0.0, 0.0, 1.0),
        time, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
    tween.start()
    yield(tween, "tween_completed")

func lbox_out(time):
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
