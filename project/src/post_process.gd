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
var shader

func _ready():
    palette_tween = Util.new_tween(self)
    shader = $"retrorizer/rect"

func set_palette(idx):
    idx = idx % len(palettes)
    shader.get_material().set_shader_param("palette_a", palettes[idx])
        
func set_palette_back(idx):
    idx = idx % len(palettes)
    shader.get_material().set_shader_param("palette_b", palettes[idx])
        
# 0.0 => palette A, 1.0 => palette B
func set_palette_blend(n):
    shader.get_material().set_shader_param("palette_blend", n)
    
# Change the game's color palette over a set amount of time.
func change_palette(idx, time = 0.5):

    # print("changing color palette from %s to %s in %s seconds" % [current_palette, idx, time])
    set_palette_back(current_palette)
    set_palette(idx)

    set_palette_blend(1.0)
    palette_tween.remove_all()
    palette_tween.interpolate_method(self, "set_palette_blend",
        1.0, 0.0,
        time, Tween.TRANS_LINEAR, Tween.EASE_OUT)
    palette_tween.start()
    yield(palette_tween, "tween_all_completed")

    current_palette = idx
