shader_type canvas_item;

uniform float brightness = 1.0;
uniform float contrast = 1.0;
uniform float saturation = 1.0;

void fragment() {
    
    COLOR = texture(TEXTURE, UV);
    vec4 screen_color = texture(SCREEN_TEXTURE, SCREEN_UV);

    COLOR.rgb = mix(vec3(0.0), COLOR.rgb, brightness);
    COLOR.rgb = mix(vec3(0.5), COLOR.rgb, contrast);
    COLOR.rgb = mix(vec3(dot(vec3(1.0), COLOR.rgb) * 0.33333), COLOR.rgb, saturation);
    
    COLOR += screen_color;
        
}