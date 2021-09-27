extends CanvasLayer
tool

export (Texture) var bg_texture;
export (float, 0.0, 1.0) var opacity = 0.5;

onready var game = $"/root/World" as Game
var sprite: Sprite

func _ready():
    
    # add background sprite
    sprite = Sprite.new()
    add_child(sprite)
    
    sprite.texture = bg_texture
    sprite.centered = false
    sprite.modulate = Color(opacity, opacity, opacity)
    sprite.material = ShaderMaterial.new()
    sprite.material.shader = load("res://shaders/grayscale.gdshader")

    sprite.offset = game.get_camera().get_camera_origin() * 0.1
    
func _process(_delta):
    
    if Engine.editor_hint and sprite:
        sprite.modulate = Color(opacity, opacity, opacity)

    if game:
        sprite.position = game.get_camera().get_camera_origin() * 0.1
    
    
    
