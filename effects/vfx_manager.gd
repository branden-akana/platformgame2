#===============================================================================
# Post-Processor
#
# Contains scripting for the game's shaders
# This script also contains:
# - controls for the color palette used by the levels
#===============================================================================

class_name VFXManager extends CanvasLayer


@export var palettes: Array[Texture2D]

@export var current_palette: int = 0 :
	get:
		return current_palette
	set(new_palette):
		current_palette = new_palette
		change_palette(new_palette)

@export var b_post_process_enabled : bool :
	get:
		return b_post_process_enabled # TODOConverter40 Non existent get function 
	set(enabled):
		b_post_process_enabled = enabled
		if $color_indexer:
			$color_indexer.visible = enabled
			$vignette.visible = enabled
			$pixelator.visible = enabled

@export_range(0.0, 1.0) var palette_blend : float :
	get:
		return _get_palette_blend()
	set(blend):
		palette_blend = blend
		_set_palette_blend(blend)


@onready var palette_tween: Tween
@onready var shader = $color_indexer

# func _process(_delta) -> void:
# 	if has_node("%camera"):
# 		position = $%camera.focus

func _set_palette(idx):
	idx = idx % len(palettes)
	if shader:
		shader.get_material().set_shader_parameter("palette_a", palettes[idx])
		
func _set_palette_back(idx):
	idx = idx % len(palettes)
	if shader:
		shader.get_material().set_shader_parameter("palette_b", palettes[idx])
		
# 0.0 => palette A, 1.0 => palette B
func _set_palette_blend(n):
	if shader:
		shader.get_material().set_shader_parameter("palette_blend", n)

func _get_palette_blend():
	if shader:
		return shader.get_material().get_shader_parameter("palette_blend")
	else:
		return 0.0
	
# Change the game's color palette over a set amount of time.
#
func change_palette(idx, time = 0.5):

	# print("changing color palette from %s to %s in %s seconds" % [current_palette, idx, time])
	_set_palette_back(current_palette)
	_set_palette(idx)

	if Engine.is_editor_hint():
		notify_property_list_changed()

	if palette_tween:
		palette_tween.kill()

	palette_tween = create_tween()
	palette_blend = 1.0 - palette_blend
	palette_tween.tween_property(self, "palette_blend",
		0.0, time).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_OUT)

	await palette_tween.finished

