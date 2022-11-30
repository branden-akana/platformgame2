
group_uniforms Dithering;

uniform bool dither_enabled = false;
uniform bool dither_lab = false;
uniform float dither_amt: hint_range(-10.0, 10.0) = 1.0;
uniform float dither_shf: hint_range(-10.0, 10.0) = 0.0;

group_uniforms;

float distance_squared(vec3 a, vec3 b) {
	
	float x = b.x - a.x;
	float y = b.y - a.y;
	float z = b.z - a.z;
	return x*x + y*y + z*z;
}

/*
* Port of https://github.com/antimatter15/rgb-lab/blob/master/color.js#L28-L47
* Converts an RGB color to CIE L*ab format.
*/
vec3 rgb_to_lab(vec3 rgb) {
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

/*
* Port of https://github.com/antimatter15/rgb-lab/blob/master/color.js#L52-L68
* Gets the delta E between two LAB colors.
*/
float distance_lab(vec3 a, vec3 b) {
	
	vec3 labA = rgb_to_lab(a);
	vec3 labB = rgb_to_lab(b);
	
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
		//return distance_lab(a, b);
		return distance(rgb_to_lab(a), rgb_to_lab(b));
	}
	
	return distance_squared(a, b);
	
}

struct ColorResults {
	float dist_1;
	float dist_2;
	vec2 uv_1;
	vec2 uv_2;
	vec4 color_a;
	vec4 color_b;
};

/*
* Test a color against a color palette, and return a result struct containing:
* - The UV of the closest palette color found
* - The UV of the 2nd closest palette color found
* - The color distance between the closest palette color and the tested color
* - The color distance between the closest palette color and the 2nd closest palette color
*/
ColorResults get_closest_colors(vec4 color, sampler2D palette, int palette_size) {
	
	float max_dist_1 = 10000.0;
	float max_dist_2 = 10000.0;

	vec2 uv_1 = vec2(0, 0); // UV of the closest color
	vec2 uv_2 = vec2(0, 0); // UV of the 2nd closest color
	
	vec4 color_a = vec4(0);
	vec4 color_b = vec4(0);
	
	for(float u = 0.0; u < float(palette_size); u += 1.0) {

		vec2 pal_uv = vec2(u / float(palette_size), 0.0);
		vec4 pal_color = texture(palette, pal_uv);
		float dist = _distance(color.rgb, pal_color.rgb);
		
		if( dist < max_dist_1 ) {

			if ( max_dist_1 < max_dist_2 ) {
				max_dist_2 = max_dist_1;
				uv_2 = uv_1;
				color_b = color_a;
			}

			max_dist_1 = dist;
			uv_1 = pal_uv;
			color_a = pal_color;
		}
	}

	ColorResults results;
	results.color_a = color_a; // the closest color
	results.color_b = color_b; // the second closest color
	results.uv_1 = uv_1; // UV of the closest color
	results.uv_2 = uv_2; // UV of the second closest color
	// distance between the tested color and the closest color
	results.dist_1 = max_dist_1; 
	// distance between the closest color and second closest color
	results.dist_2 = _distance(texture(palette, uv_1).rgb, texture(palette, uv_2).rgb);
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

/*
* Return the closest color in the palette from the given color.
*/
vec2 get_indexed_color(vec4 color, sampler2D palette, int palette_size) {
	return get_closest_colors(color, palette, palette_size).uv_1;
}

/*
* Return the dithered color from the given color.
*/
vec2 get_dithered_color(vec4 color, vec4 frag_coord, sampler2D palette, int palette_size) {
	ColorResults res = get_closest_colors(color, palette, palette_size);

	float index_pixel = index_value(frag_coord.xy);
	
	if ( dither_lab ) { index_pixel += 0.26; } else { index_pixel += 0.1; }
	
	float diff = _distance(color.rgb, res.color_a.rgb) / _distance(res.color_b.rgb, res.color_a.rgb);

	float dist_norm = res.dist_1 / res.dist_2;

	if (diff < index_pixel * dither_amt + dither_shf) { return res.uv_1; }
	else { return res.uv_2; }
}

// Dither Opacity Shader by Firerabbit
bool get_dithered_alpha(vec4 color, vec4 frag_coord, float dither_shift) {

	float index_pixel = index_value(frag_coord.xy);
	
	if (color.a < index_pixel + dither_shift) {
		return false;
	}
	
	return true;
}
