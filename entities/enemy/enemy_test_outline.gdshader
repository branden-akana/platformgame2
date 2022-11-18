shader_type canvas_item;

uniform int shadow_size = 2;
uniform float shadow_choke = 2.0;
uniform vec3 shadow_color: source_color = vec3(1);

void fragment() {
	
	const vec2 lookaround[] = {
		vec2(-1, 1),  vec2(0, 1),  vec2(1, 1),
		vec2(-1, 0),  vec2(0, 0),  vec2(1, 0),
		vec2(-1, -1), vec2(0, -1), vec2(1, -1)
	};
	
	vec2 pixel_size = 1.0 / vec2(textureSize(TEXTURE, 0));
	
	if (COLOR.a == 0.0) {
		for (int i = -shadow_size; i <= shadow_size; i++) {
			for (int j = -shadow_size; j <= shadow_size; j++) {
				if (texture(TEXTURE, UV + pixel_size * vec2(float(i), float(j))).a == 1.0) {
					COLOR.a += 1.0 / pow(float(shadow_size) * 2.0, shadow_choke);
				}
			}
		}
		COLOR.rgb = shadow_color;
	}
	//COLOR = texture(SCREEN_TEXTURE, SCREEN_UV);
}
