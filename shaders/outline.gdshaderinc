group_uniforms DropShadows;

uniform int shadow_size = 2;
uniform float shadow_choke = 2.0;
uniform vec3 shadow_color: source_color = vec3(1);

uniform int cutout_size = 1;

group_uniforms;

vec4 draw_outline(vec4 color, sampler2D tex, vec2 uv) {
	vec2 pixel_size = 1.0 / vec2(textureSize(tex, 0));
	
	if (color.a == 0.0) {
		for (int i = -shadow_size; i <= shadow_size; i++) {
			for (int j = -shadow_size; j <= shadow_size; j++) {
				if (texture(tex, uv + pixel_size * vec2(float(i), float(j))).a == 1.0) {
					color.a += 1.0 / pow(float(shadow_size) * 2.0, shadow_choke);
				}
			}
		}
		for (int i = -cutout_size; i <= cutout_size; i++) {
			for (int j = -cutout_size; j <= cutout_size; j++) {
				if (texture(tex, uv + pixel_size * vec2(float(i), float(j))).a == 1.0) {
					color.a -= 1.0 / float(shadow_size) * 2.0;
				}
			}
		}
		color.rgb = shadow_color;
	}
	
	return color;
}