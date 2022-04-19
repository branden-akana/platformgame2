/*
    Pixelization (with a specified pixel size)
    
    This version samples SCREEN_TEXTURE which will process the entire screen.
*/

shader_type canvas_item;
render_mode skip_vertex_transform;

// texture params

uniform bool screen = true;

// pixelation params

uniform float pixel_size = 4.0;
uniform float pixel_smoothing = 0.5;

// noise params

uniform float noise_strength = 0.015;

vec2 get_pixel_ratio(float pixsize, sampler2D tex) {
    // pixel size / texture size
    return pixsize / vec2(textureSize(tex, 0));
}


// "random" number generator
float rand(vec2 co) {
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
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
    vec4 color_aa;
    vec4 color;
    
    // anti-aliased pixel color
    // ------------------------
    
    vec2 screen_ratio;
    if (screen) { screen_ratio = get_pixel_ratio(pixel_size, SCREEN_TEXTURE); }
    else { screen_ratio = get_pixel_ratio(pixel_size, TEXTURE); }
    
    //vec2 pixel_uv = (floor(SCREEN_UV / screen_ratio) * screen_ratio) + (screen_ratio / 2.0);
    pixel_uv = (floor(uv / screen_ratio) * screen_ratio);
    
    if (screen) { color_aa = textureLod(SCREEN_TEXTURE, pixel_uv, 0.0); }
    else { color_aa = textureLod(TEXTURE, pixel_uv, 0.0); }

    // raw pixel color
    // ---------------
    
    pixel_uv = floor((FRAGCOORD.xy) / pixel_size) * pixel_size;
    
    if (screen) { color = texelFetch(SCREEN_TEXTURE, ivec2(pixel_uv), 0); }
    else { color = texelFetch(TEXTURE, ivec2(pixel_uv), 0); }
    
    // blend final color
    COLOR = mix(color, color_aa, pixel_smoothing);

    // noise
    // =========================================================================
    
    //COLOR = mix(COLOR, vec4(vec3(rand(pixel_uv + rand(vec2(TIME)))), 1.0), 0.03);
    float n = abs(rand(pixel_uv + rand(vec2(floor(TIME * 10.0)))));
    //n = clamp(n, 0.0, 1.0);
    COLOR = mix(COLOR, COLOR + vec4(vec3(n), 1.0), noise_strength);
}