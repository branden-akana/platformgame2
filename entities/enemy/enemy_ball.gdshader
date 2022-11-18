/*
	Dither Opacity Shader by Firerabbit
	
	MIT License
*/

shader_type canvas_item;

uniform float _alpha_clip : hint_range(0,1) = 0.01;

const vec4 dither[4] = {
	vec4(0.00, 0.50, 0.00, 0.38),
	vec4(0.88, 0.25, 0.75, 0.13),
	vec4(0.00, 0.38, 0.00, 0.50),
	vec4(0.75, 0.13, 0.88, 0.25)
	};
	
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


float getValue(int x, int y) {
	float res = 0.0;
	switch(y) {
		case 0:
			res = dither[x].r;
			break;
		case 1:
			res = dither[x].g;
			break;
		case 2:
			res = dither[x].b;
			break;
		case 3:
			res = dither[x].a;
			break;		
	}
	return res;
}

void fragment() {
	vec4 color = texture(SCREEN_TEXTURE, SCREEN_UV);
	
	float limit = index_value(FRAGCOORD.xy);
	
	if (color.a < limit || color.a < _alpha_clip) {
		discard;
	}        
	
	COLOR = color.rgba;
}