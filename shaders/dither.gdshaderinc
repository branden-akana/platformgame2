
group_uniforms Dithering;

uniform bool dither_enabled = false;
uniform float dither_amt: hint_range(-10.0, 10.0) = 1.0;
uniform float dither_shf: hint_range(-10.0, 10.0) = 0.0;

group_uniforms Palette;

// Bitfield of colors to use when finding closest colors
// Default: 255 = 0b11111111
uniform lowp uint palette_mask = 255;

group_uniforms;

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
float distance_lab(vec3 rgb_a, vec3 rgb_b) {
	
	const float WHT_L = 1.0, WHT_C = 1.0, WHT_H = 1.0;
	
	vec3 lab1 = rgb_to_lab(rgb_a);
	vec3 lab2 = rgb_to_lab(rgb_b);
	
	float xC1 = sqrt( pow(lab1.y, 2.0) + pow(lab1.z, 2.0) );
	float xC2 = sqrt( pow(lab2.y, 2.0) + pow(lab2.z, 2.0) );
	
	float xDL = lab2.x - lab1.x;
	float xDC = xC2 - xC1;
	float xDE = distance(lab1, lab2);

	float xDH = (xDE * xDE) - (xDL * xDL) - (xDC * xDC);
	if( xDH > 0.0 ) {
		xDH = sqrt(xDH);
	}
	else {
		xDH = 0.0;
	}
	
	float xSC = 1.0 + 0.045 * xC1;
	float xSH = 1.0 + 0.015 * xC1;
	
	xDL /= WHT_L;
	xDC /= WHT_C * xSC;
	xDH /= WHT_H * xSH;

	return sqrt(xDL*xDL + xDC*xDC + xDH*xDH);
}

float sq(float x) { return x * x; }

// https://gist.github.com/yyny/3b54ff26ab4f8fd0aad468dd144191c2
// Luma-corrected RGB color distance
float _distance_luma(vec3 a, vec3 b) {
	vec3 diff = b - a;
	float luma1 = (a.x*0.299 + a.y*0.587 + a.z*0.114);
	float luma2 = (b.x*0.299 + b.y*0.587 + b.z*0.114);
	float dluma = luma2 - luma1;
	
	return (sq(diff.x) * 0.299 + sq(diff.y) * 0.587 + sq(diff.z) * 0.114) * sq(dluma) * 0.75;
}

float _distance(vec3 a, vec3 b) {
	
#ifdef DITHER_LAB
	// more accurate color dithering
	//return distance_lab(a, b);
	return distance(rgb_to_lab(a), rgb_to_lab(b));
#else
	return _distance_luma(a, b);
#endif
}

struct ColorPairResult {
	vec4 color_a;
	vec2 uv_1;
	vec4 color_b;
	vec2 uv_2;
	float dist_1;
	float dist_12;
};

struct ColorResult {
	vec3 color;
	vec2 uv;
};

/*
* Test a color against a color palette, and return a result struct containing:
* - The UV of the closest palette color found
* - The UV of the 2nd closest palette color found
* - The color distance between the closest palette color and the tested color
* - The color distance between the closest palette color and the 2nd closest palette color
*/
ColorPairResult find_closest_colors(vec4 color, sampler2D palette, int palette_size) {
	
	//bool[8] mask = {pal_1, pal_2, pal_3, pal_4, pal_5, pal_6, pal_7, pal_8};
	
	float max_dist_1 = 10000.0;
	float max_dist_2 = 10000.0;

	vec2 uv_1 = vec2(-1.0); // UV of the closest color
	vec2 uv_2 = vec2(-1.0); // UV of the 2nd closest color
	
	vec4 color_a = vec4(-20, 0, 0, 1);
	vec4 color_b = vec4(-20, 0, 0, 1);
	
	for(float u = 0.0; u < float(palette_size); u += 1.0) {
		if( bitfieldExtract(palette_mask, int(u), 1) == 0u ) { continue; }
		//if( !mask[int(u)] ) { continue; }

		vec2 pal_uv = vec2(u / float(palette_size), 0.0);
		vec4 pal_color = texture(palette, pal_uv);
		float dist = _distance(pal_color.rgb, color.rgb);
		float closest_dist = _distance(color_a.rgb, color.rgb);
		
		if( dist < closest_dist ) {

			max_dist_2 = max_dist_1;
			uv_2 = uv_1;
			color_b = color_a;

			max_dist_1 = closest_dist;
			uv_1 = pal_uv;
			color_a = pal_color;
		}
		else if ( dist < _distance(color_b.rgb, color.rgb) ) {
			
			max_dist_2 = dist;
			uv_2 = pal_uv;
			color_b = pal_color;
		}
	}

	ColorPairResult results;
	results.color_a = color_a; // the closest color
	results.color_b = color_b; // the second closest color
	results.uv_1 = uv_1; // UV of the closest color
	results.uv_2 = uv_2; // UV of the second closest color
	// distance between the tested color and the closest color
	results.dist_1 = max_dist_1; 
	// distance between the closest color and second closest color
	results.dist_12 = _distance(color_a.rgb, color_b.rgb);
	return results;
}

ColorResult find_closest_color(vec3 src, sampler2D palette, int palette_size) {

	vec3 color = vec3(-20.0); 
	vec2 uv = vec2(-1.0); // UV of the closest color
	
	for(int u = 0; u < palette_size; u += 1) {
		if( bitfieldExtract(palette_mask, int(u), 1) == 0u ) { continue; }

		vec2 pal_uv = vec2(float(u) / float(palette_size), 0.0);
		vec3 pal_color = texture(palette, pal_uv).rgb;
		
		if( _distance(pal_color.rgb, src.rgb) < _distance(color.rgb, src.rgb) ) {
			color = pal_color;
			uv = pal_uv;
		}
	}

	return ColorResult(color, uv);
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
	return find_closest_color(color.rgb, palette, palette_size).uv;
}

/*
* Return the dithered color from the given color.
*/
vec2 get_dithered_color(vec4 color, vec4 frag_coord, sampler2D palette, int palette_size) {

	float index_pixel = index_value(frag_coord.xy) * dither_amt + dither_shf;
	
#ifdef DITHER_LAB
// CIELAB Delta E color dithering

	ColorPairResult res = find_closest_colors(color, palette, palette_size);

	index_pixel += 0.26; 
	float diff = res.dist_1 / res.dist_12;

	if (diff < index_pixel) { return res.uv_1; }
	else { return res.uv_2; }

#else
// bisqwit-based color dithering

	ColorResult res = find_closest_color(color.rgb, palette, palette_size);

	if( res.color != color.rgb ) {
		float threshold = 1.0 / sqrt(float(palette_size));
		color.rgb += vec3((index_pixel - 0.5) * threshold);
		color = clamp(color, 0.0, 1.0);
		return find_closest_color(color.rgb, palette, palette_size).uv;
	}

	return res.uv;

#endif
}

// Dither Opacity Shader by Firerabbit
bool get_dithered_alpha(vec4 color, vec4 frag_coord) {

	float index_pixel = index_value(frag_coord.xy) + dither_shf;
	
	if (color.a < index_pixel) {
		return false;
	}
	
	return true;
}
