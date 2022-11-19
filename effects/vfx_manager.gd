#===============================================================================
# Post-Processor
#
# Contains scripting for the game's shaders
# This script also contains:
# - controls for the color palette used by the levels
#===============================================================================

class_name VFXManager extends Node2D
@tool

@export (Array, Texture2D) var palettes

@export (int) var current_palette = 0 :
	get:
		return current_palette # TODOConverter40 Non existent get function 
	set(mod_value):
		mod_value  # TODOConverter40 Copy here content of change_palette

@export (bool) var b_post_process_enabled = 1 :
	get:
		return b_post_process_enabled # TODOConverter40 Non existent get function 
	set(mod_value):
		mod_value  # TODOConverter40 Copy here content of set_post_process_enabled

@export (float, 0.0, 1.0) var palette_blend = 0.0 :
	get:
		return palette_blend # TODOConverter40 Non existent get function 
	set(mod_value):
		mod_value  # TODOConverter40 Copy here content of _set_palette_blend

@onready var palette_tween = $tween
@onready var shader = $canvas_layer/color_indexer

func _process(delta) -> void:
    if Game.has_method("get_camera_3d"):
        position = Game.get_camera_3d().focus

func _set_palette(idx):
    idx = idx % len(palettes)
    shader.get_material().set_shader_parameter("palette_a", palettes[idx])
        
func _set_palette_back(idx):
    idx = idx % len(palettes)
    shader.get_material().set_shader_parameter("palette_b", palettes[idx])
        
# 0.0 => palette A, 1.0 => palette B
func _set_palette_blend(n):
    palette_blend = n
    shader.get_material().set_shader_parameter("palette_blend", n)

func _get_palette_blend():
    return shader.get_material().get_shader_parameter("palette_blend")
    
# Change the game's color palette over a set amount of time.
#
func change_palette(idx, time = 0.5):

    # print("changing color palette from %s to %s in %s seconds" % [current_palette, idx, time])
    _set_palette_back(current_palette)
    _set_palette(idx)

    current_palette = idx
    if Engine.editor_hint:
        notify_property_list_changed()

    palette_tween.remove_all()
    palette_tween.interpolate_method(self, "_set_palette_blend",
        1.0 - _get_palette_blend(), 0.0,
        time, Tween.TRANS_LINEAR, Tween.EASE_OUT)
    palette_tween.start()
    await palette_tween.tween_all_completed

func set_post_process_enabled(enabled: bool) -> void:
    b_post_process_enabled = enabled
    $canvas_layer/color_indexer.visible = enabled
    $canvas_layer/vignette.visible = enabled
    $pixelator.visible = enabled
