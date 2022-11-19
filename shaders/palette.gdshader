/*
	Palette Shader

	Fixes colors to an arbitrary palette.
*/

shader_type canvas_item;

// texture params

uniform bool screen = true;
uniform bool dither = false;
uniform bool dither_lab = false;
uniform float dither_amt: hint_range(-10.0, 10.0) = 1.0;
uniform float dither_shf: hint_range(-10.0, 10.0) = 0.0;

// palette params

uniform int palette_size = 8;

global uniform sampler2D palette_key: filter_nearest;  // palette to use for determining color mapping
global uniform sampler2D palette_a: filter_nearest;    // palette to remap to (A side)
global uniform sampler2D palette_b: filter_nearest;    // palette to remap to (B side)

global uniform float palette_blend: hint_range(0.0, 1.0) = 0.0;

float distance_squared(vec3 a, vec3 b) {
	
	float x = b.x - a.x;
	float y = b.y - a.y;
	float z = b.z - a.z;
	return x*x + y*y + z*z;
}

vec3 rgb2lab(vec3 rgb) {
	float r = rgb.r / 255.0, g = rgb.g / 255.0, b = rgb.b / 255.0;
	float x, y, z;

	r = (r > 0.04045) ? pow((r + 0.055) / 1.055, 2.4) : r / 12.92;
	g = (g > 0.04045) ? pow((g + 0.055) / 1.055, 2.4) : g / 12.92;
	b = (b > 0.04045) ? pow((b + 0.055) / 1.055, 2.4) : b / 12.92;

	x = (r * 0.4124 + g * 0.3576 + b * 0.1805) / 0.95047;
	y = (r * 0.2126 + g * 0.7152 + b * 0.0722) / 1.00000;
	z = (r * 0.0193 + g * 0.1192 + b * 0.9505) / 1.08883;

	x = (x > 0.008856) ? pow(x, 1.0/3.0) : (7.787 * x) + 16.0/116.0;
	y = (y > 0.008856) ? pow(y, 1.0/3.0) : (7.787 * y) + 16.0/116.0;
	z = (z > 0.008856) ? pow(z, 1.0/3.0) : (7.787 * z) + 16.0/116.0;

	return vec3((116.0 * y) - 16.0, 500.0 * (x - y), 200.0 * (y - z));
}

// calculate the perceptual distance between colors in CIELAB
// https://github.com/THEjoezack/ColorMine/blob/master/ColorMine/ColorSpaces/Comparisons/Cie94Comparison.cs

float distance_lab(vec3 a, vec3 b) {
	
	vec3 labA = rgb2lab(a);
	vec3 labB = rgb2lab(b);
	
	float deltaL = labA[0] - labB[0];
	float deltaA = labA[1] - labB[1];
	float deltaB = labA[2] - labB[2];

	float c1 = sqrt(labA[1] * labA[1] + labA[2] * labA[2]);
	float c2 = sqrt(labB[1] * labB[1] + labB[2] * labB[2]);

	float deltaC = c1 - c2;
	float deltaH = deltaA * deltaA + deltaB * deltaB - deltaC * deltaC;

	deltaH = deltaH < 0.0 ? 0.0 : sqrt(deltaH);

	float sc = 1.0 + 0.045 * c1;
	float sh = 1.0 + 0.015 * c1;
	float deltaLKlsl = deltaL / (1.0);
	float deltaCkcsc = deltaC / (sc);
	float deltaHkhsh = deltaH / (sh);
	float i = deltaLKlsl * deltaLKlsl + deltaCkcsc * deltaCkcsc + deltaHkhsh * deltaHkhsh;

	return i < 0.0 ? 0.0 : sqrt(i);
}

float _distance(vec3 a, vec3 b) {
	//return distance(a, b);
	if ( dither_lab ) {
		// more accurate color dithering
		return distance_lab(a, b);
	}
	
	return distance_squared(a, b);
	
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
		float dist = _distance(color.rgb, texture(palette_key, pal_uv).rgb);
		
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
	results.dist_2 = _distance(texture(palette_key, uv_1).rgb, texture(palette_key, uv_2).rgb);
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
	
	if ( dither_lab ) {
		index_pixel += 0.3;
	}

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