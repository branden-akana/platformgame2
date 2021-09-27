shader_type canvas_item;
 
void fragment() {
    COLOR = texture(TEXTURE, UV); 
    COLOR.rgb = vec3((COLOR.r + COLOR.g + COLOR.b) / 3.0);
}