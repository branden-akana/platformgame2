/*
    Retro Shader
    
    This shader implements the following effects:
    - Pixelization (with a specified pixel size)
    - Noise
    - Color palette (depends on the green channel of a pixel)
    
    This version samples SCREEN_TEXTURE which will process the entire screen.
*/

shader_type canvas_item;

uniform sampler2D palette_a;
uniform sampler2D palette_b;

uniform float palette_blend = 0.0;
uniform float pixel_size = 4.0;

// "random" number generator
float rand(vec2 co) {
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

void fragment() {
    // pixelize screen
    float pixsize = float(pixel_size);
	vec2 screen_size = vec2(textureSize(SCREEN_TEXTURE, 0));
	vec2 screen_ratio = pixsize / screen_size;
	//vec2 pixel_uv = (floor(SCREEN_UV / screen_ratio) * screen_ratio) + (screen_ratio / 2.0);
    vec2 pixel_uv = (floor(SCREEN_UV / screen_ratio) * screen_ratio);
	COLOR = textureLod(SCREEN_TEXTURE, pixel_uv, 0.0);
        
    // noise
    //COLOR = mix(COLOR, vec4(vec3(rand(pixel_uv + rand(vec2(TIME)))), 1.0), 0.03);
    float n = abs(rand(pixel_uv + rand(vec2(floor(TIME * 10.0)))));
    //n = clamp(n, 0.0, 1.0);
    COLOR = mix(COLOR, COLOR + vec4(vec3(n), 0.0), 0.015);
    
    // use color palette
    float u = (floor(COLOR.g * 4.0) / 4.0) + (1.0 / 8.0);
    float v = 0.0; // selects which row of the palette to use
    vec4 palette_color_a = texture(palette_a, vec2(u, v));
    vec4 palette_color_b = texture(palette_b, vec2(u, v));
    vec4 palette_color = mix(palette_color_a, palette_color_b, palette_blend);
    COLOR = vec4(palette_color.rgb, COLOR.a);  
}

void light() {
    // use color palette
    float u = floor(COLOR.g * 8.0) / 8.0 + (1.0 / 16.0);
    float v = 0.0; // selects which row of the palette to use
    vec4 palette_color_a = texture(palette_a, vec2(u, v));
    vec4 palette_color_b = texture(palette_b, vec2(u, v));
    vec4 palette_color = mix(palette_color_a, palette_color_b, palette_blend);
    //LIGHT = vec4(palette_color.rgb, COLOR.a);
    SHADOW_COLOR = vec4(0.0);
    LIGHT = vec4(0.0);
    LIGHT_COLOR = vec4(0.0);
    LIGHT_HEIGHT = 0.0;
}