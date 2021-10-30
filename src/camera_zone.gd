extends Area2D
class_name CameraZone
tool

export (Vector2) var region_size = Vector2(20, 11.25)
export var palette_idx = 0

onready var collision: CollisionShape2D = $collision

func _ready():

    collision.shape = RectangleShape2D.new()
    collision.shape.extents = (region_size * 64 - Vector2(32, 32)) / 2
    collision.position = region_size * 64 / 2

    # connect("body_entered", Game.get_camera(), "on_body_entered")

# debug visuals

func _draw():
    
    if Engine.editor_hint:
        var color = Color(1.0, 1.0, 1.0)
        draw_rect(Rect2(Vector2(0, 0), region_size * 64), color, false, 4.0)
        draw_rect(Rect2(Vector2(16, 16), (region_size * 64) - Vector2(32, 32)), color, false, 4.0)
    
func _process(delta):
    
    if Engine.editor_hint:
        position = (position / 16).floor() * 16
        collision.shape.extents = (region_size * 64 - Vector2(32, 32)) / 2
        collision.position = region_size * 64 / 2
        update()
        
    

