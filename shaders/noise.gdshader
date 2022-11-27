shader_type canvas_item;

uniform float noise_strength = 0.015;
uniform float noise_speed = 10.0;

#include "res://shaders/noise.gdshaderinc"

void fragment() {
	
	//COLOR = mix(COLOR, vec4(vec3(rand(pixel_uv + rand(vec2(TIME)))), 1.0), 0.03);
	float n = abs(rand(UV + rand(vec2(floor(TIME * noise_speed)))));
	n = clamp(n, 0.0, 1.0);
	COLOR = mix(COLOR, COLOR + vec4(vec3(n), 1.0), noise_strength);
}
