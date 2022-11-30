/*
	Palette Shader

	Fixes colors to an arbitrary palette.
*/

shader_type canvas_item;

#include "res://shaders/dither.gdshaderinc"
#include "res://shaders/outline.gdshaderinc"

// texture params

uniform bool screen = true;
uniform bool unlit = false;

// palette params

uniform int palette_size = 8;

uniform sampler2D palette_key: filter_nearest;  // palette to use for determining color mapping
uniform sampler2D palette_a: filter_nearest;    // palette to remap to (A side)
uniform sampler2D palette_b: filter_nearest;    // palette to remap to (B side)

uniform float palette_blend: hint_range(0.0, 1.0) = 0.0;

void fragment() {

	vec4 color;
	if (screen) { color = texture(SCREEN_TEXTURE, SCREEN_UV); }
	else { color = texture(TEXTURE, UV); }

	vec2 uv;
	if (dither_enabled) { uv = get_dithered_color(color, FRAGCOORD, palette_key, palette_size); }
	else { uv = get_indexed_color(color, palette_key, palette_size); }

	vec4 palette_color_a = texture(palette_a, uv);
	vec4 palette_color_b = texture(palette_b, uv);
	vec4 palette_color = mix(palette_color_a, palette_color_b, palette_blend);
	COLOR = vec4(palette_color.rgb, COLOR.a);  
	//COLOR = vec4(final_uv, 0.0, COLOR.a);
	
	COLOR = draw_outline(COLOR, TEXTURE, UV);
}

void light() {
	if( unlit ) {
		LIGHT = vec4(0);
	} else {
		LIGHT = vec4(LIGHT_COLOR.rgb * COLOR.rgb * LIGHT_ENERGY, LIGHT_COLOR.a);
	}
}
