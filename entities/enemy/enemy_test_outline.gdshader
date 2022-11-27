shader_type canvas_item;

#include "res://shaders/outline.gdshaderinc"

void fragment() {
	COLOR = draw_outline(COLOR, TEXTURE, UV);
}
