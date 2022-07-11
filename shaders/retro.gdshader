/*
    Retro Shader
    
    This shader implements the following effects:
    - Pixelization (with a specified pixel size)
    - Noise
    - Color palette (depends on the green channel of a pixel)
    
    This version samples SCREEN_TEXTURE which will process the entire screen.
*/

shader_type canvas_item;
render_mode skip_vertex_transform;

// texture params

uniform bool screen = true;

// pixelation params

uniform float pixel_size = 4.0;
uniform bool antialiased = false;

// palette params

uniform sampler2D palette_a;
uniform sampler2D palette_b;

uniform float palette_layer = 0;
uniform float palette_blend = 0.0;

// noise params

uniform float noise_strength = 0.015;

// "random" number generator
float rand(vec2 co) {
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}
vec2 get_pixel_ratio(float pixsize, sampler2D tex) {
    // pixel size / texture size
    return pixsize / vec2(textureSize(tex, 0));
}

void vertex() {
    vec4 world_vertex = WORLD_MATRIX * vec4(VERTEX, 0.0, 1.0);
    world_vertex = floor(world_vertex / pixel_size) * pixel_size;
    VERTEX = world_vertex.xy;
}

void fragment() {
    vec2 uv;
    if (screen) { uv = SCREEN_UV; } else { uv = UV; }

    // pixelize screen
    // =========================================================================
      
    vec2 pixel_uv;
      
    if (antialiased) {
        
        vec2 screen_ratio;
        if (screen) { screen_ratio = get_pixel_ratio(pixel_size, SCREEN_TEXTURE); }
        else { screen_ratio = get_pixel_ratio(pixel_size, TEXTURE); }
        
        pixel_uv = (floor(uv / screen_ratio) * screen_ratio) + (screen_ratio / 2.0);
        //pixel_uv = (floor(uv / screen_ratio) * screen_ratio);
        
        if (screen) { COLOR = textureLod(SCREEN_TEXTURE, pixel_uv, 0.0); }
        else { COLOR = textureLod(TEXTURE, pixel_uv, 0.0); }
        
    } else {
        
        pixel_uv = floor((FRAGCOORD.xy) / pixel_size) * pixel_size;
        
        if (screen) { COLOR = texelFetch(SCREEN_TEXTURE, ivec2(pixel_uv), 0); }
        else { COLOR = texelFetch(TEXTURE, ivec2(pixel_uv), 0); }
    }
    
    // noise
    // =========================================================================
    
    //COLOR = mix(COLOR, vec4(vec3(rand(pixel_uv + rand(vec2(TIME)))), 1.0), 0.03);
    float n = abs(rand(pixel_uv + rand(vec2(floor(TIME * 10.0)))));
    //n = clamp(n, 0.0, 1.0);
    COLOR = mix(COLOR, COLOR + vec4(vec3(n), 1.0), noise_strength);
    
    // color palette
    // =========================================================================
    
    float u = (floor(COLOR.g * 4.0) / 4.0) + (1.0 / 8.0);
    float v = palette_layer; // selects which row of the palette to use
    vec4 palette_color_a = texture(palette_a, vec2(u, v));
    vec4 palette_color_b = texture(palette_b, vec2(u, v));
    vec4 palette_color = mix(palette_color_a, palette_color_b, palette_blend);
    COLOR = vec4(palette_color.rgb, COLOR.a);  
}