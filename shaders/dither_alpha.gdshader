shader_type canvas_item;

#include "res://shaders/dither.gdshaderinc"

uniform bool screen = false;
uniform float dither_shift : hint_range(-10, 10) = 0.001;


void fragment() {
	vec4 color;
	if ( screen ) { color = texture(SCREEN_TEXTURE, SCREEN_UV); }
	else { color = COLOR; }
	
	if (!get_dithered_alpha(color, FRAGCOORD)) {
		discard;
	}
	
	COLOR = color;
}