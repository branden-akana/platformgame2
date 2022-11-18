/*
	Dither Opacity Shader by Firerabbit
	
	MIT License
*/

shader_type canvas_item;

uniform bool screen = false;

uniform float dither_shift : hint_range(-10, 10) = 0.001;
	
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

void fragment() {
	vec4 color;
	if ( screen ) { color = texture(SCREEN_TEXTURE, SCREEN_UV); }
	else { color = COLOR; }
	
	float index_pixel = index_value(FRAGCOORD.xy);
	
	if (color.a < index_pixel + dither_shift ) {
		discard;
	}        
	
	COLOR = color;
}