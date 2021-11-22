#===============================================================================
# Post-Processor
#
# Contains scripting for the game's shaders
# This script also contains:
# - controls for the color palette used by the levels
#===============================================================================

extends Node2D

export (Array, Texture) var palettes
export var current_palette = 0

var palette_tween
var palette_shader_bg

func _ready():
    palette_tween = Util.new_tween(self)
    palette_shader_bg = $"palette_bg/shader"

func set_palette(idx):
    if idx < len(palettes):
        current_palette = idx
        palette_shader_bg.get_material().set_shader_param("palette_a", palettes[idx])
        
func set_palette_back(idx):
    if idx < len(palettes):
        palette_shader_bg.get_material().set_shader_param("palette_b", palettes[idx])
        
# 0.0 => palette A, 1.0 => palette B
func set_palette_blend(n):
    palette_shader_bg.get_material().set_shader_param("palette_blend", n)
    
func change_palette(idx, time = 0.5):
    if idx != current_palette:
        set_palette_back(current_palette)
        set_palette(idx)
        if time == 0:
            set_palette_blend(0.0)
            yield(get_tree(), "idle_frame")
        else:
            set_palette_blend(1.0)
            palette_tween.interpolate_method(self, "set_palette_blend",
                1.0, 0.0,
                time, Tween.TRANS_LINEAR, Tween.EASE_OUT)
            palette_tween.start()
            yield(palette_tween, "tween_completed")
    else:
        yield(get_tree(), "idle_frame")
