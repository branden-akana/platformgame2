extends Sprite

export (Texture) var bg_texture;
export (float, 0.0, 1.0) var opacity = 0.5;

var origin

func _ready():
    
    texture = bg_texture
    centered = false
    modulate = Color(opacity, opacity, opacity)
    material = ShaderMaterial.new()
    material.shader = load("res://shaders/grayscale.gdshader")
    
    origin = position
    
func _process(_delta):
    
    if Engine.editor_hint:
        modulate = Color(opacity, opacity, opacity)
    else:
        position = origin + (Game.get_camera().get_camera_origin() - origin) * 0.9
    
    
    
