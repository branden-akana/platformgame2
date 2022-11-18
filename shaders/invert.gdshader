shader_type canvas_item;

// screen-space color inverter
void fragment() {
	vec4 color = texture(SCREEN_TEXTURE, SCREEN_UV);
	color.rgb = vec3(1.0, 1.0, 1.0) - color.rgb;
	COLOR = color;
}
