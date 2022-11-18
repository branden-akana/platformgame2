/*
	Palette Shader

	Fixes colors to an arbitrary palette.
*/

shader_type canvas_item;

// texture params

uniform bool screen = true;
uniform bool dither = false;
uniform float dither_amt: hint_range(-10.0, 10.0) = 1.0;
uniform float dither_shf: hint_range(-10.0, 10.0) = 0.0;

// palette params

uniform int palette_size = 8;

uniform sampler2D palette_key: filter_nearest;  // palette to use for determining color mapping
uniform sampler2D palette_a: filter_nearest;    // palette to remap to (A side)
uniform sampler2D palette_b: filter_nearest;    // palette to remap to (B side)

uniform float palette_blend: hint_range(0.0, 1.0) = 0.0;


float distance_squared(vec3 a, vec3 b) {
	
	float x = b.x - a.x;
	float y = b.y - a.y;
	float z = b.z - a.z;
	return x*x + y*y + z*z;
}

struct ColorResults {
	float dist_1;
	float dist_2;
	vec2 uv_1;
	vec2 uv_2;
};

ColorResults test_color(vec4 color) {
	
	float max_dist_1 = 10000.0;
	float max_dist_2 = 10000.0;

	vec2 uv_1 = vec2(0, 0); // UV of the closest color
	vec2 uv_2 = vec2(0, 0); // UV of the 2nd closest color
	
	for(float u = 0.0; u < float(palette_size); u += 1.0) {

		vec2 pal_uv = vec2(u / float(palette_size), 0.0);
		float dist = distance(color.rgb, texture(palette_key, pal_uv).rgb);
		
		if( dist < max_dist_1 ) {

			if ( max_dist_1 < max_dist_2 ) {
				max_dist_2 = max_dist_1;
				uv_2 = uv_1;
			}

			max_dist_1 = dist;
			uv_1 = pal_uv;
		}
	}

	ColorResults results;
	results.uv_1 = uv_1;
	results.uv_2 = uv_2;
	results.dist_1 = max_dist_1;
	results.dist_2 = distance(texture(palette_key, uv_1).rgb, texture(palette_key, uv_2).rgb);
	return results;
}

float index_value(vec2 pixel_coord){
	//This can be any matrix with the right modifications to the rest of the function.
	const int index_matrix_8x8[64] = int[](0,  32, 8,  40, 2,  34, 10, 42,
										48, 16, 56, 24, 50, 18, 58, 26,
										12, 44, 4,  36, 14, 46, 6,  38,
										60, 28, 52, 20, 62, 30, 54, 22,
										3,  35, 11, 43, 1,  33, 9,  41,
										51, 19, 59, 27, 49, 17, 57, 25,
										15, 47, 7,  39, 13, 45, 5,  37,
										63, 31, 55, 23, 61, 29, 53, 21);
	
	int x = int(pixel_coord.x) % 8;
	int y = int(pixel_coord.y) % 8;
	return float(index_matrix_8x8[(x + y * 8)]) / 64.0;
}

vec2 dither_color(vec4 color, vec4 frag_coord) {

	ColorResults res = test_color(color);

	float index_pixel = index_value(frag_coord.xy);

	float dist_norm = res.dist_1 / res.dist_2;

	if (dist_norm < index_pixel * dither_amt + dither_shf) { return res.uv_1; }
	else { return res.uv_2; }
}

vec2 index_color(vec4 color) {
	
	ColorResults res = test_color(color);
	
	return res.uv_1;
}

void fragment() {

	vec4 color;
	if (screen) { color = texture(SCREEN_TEXTURE, SCREEN_UV); }
	else { color = texture(TEXTURE, UV); }

	vec2 uv;
	if (dither) { uv = dither_color(color, FRAGCOORD); }
	else { uv = index_color(color); }

	vec4 palette_color_a = texture(palette_a, uv);
	vec4 palette_color_b = texture(palette_b, uv);
	vec4 palette_color = mix(palette_color_a, palette_color_b, palette_blend);
	COLOR = vec4(palette_color.rgb, COLOR.a);  
	//COLOR = vec4(final_uv, 0.0, COLOR.a); 
}