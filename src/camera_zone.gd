extends Area2D
tool

export (Vector2) var region_size = Vector2(20, 11.25)

onready var collision: CollisionShape2D = $collision
onready var game = $"/root/World"

func _ready():

    collision.shape = RectangleShape2D.new()
    collision.shape.extents = (region_size * 64 - Vector2(32, 32)) / 2
    collision.position = region_size * 64 / 2

    connect("body_entered", self, "on_body_entered")

func on_body_entered(body):

    game.get_camera().set_region(position, position + (region_size * 64))
    print("entered new camera zone")

# debug visuals

func _draw():
    
    if Engine.editor_hint:
        draw_rect(Rect2(Vector2(0, 0), region_size * 64), Color(0.5, 0.5, 0.5), false, 4.0)
        draw_rect(Rect2(Vector2(16, 16), (region_size * 64) - Vector2(32, 32)), Color(0.5, 0.5, 0.5), false, 4.0)
    
func _process(delta):
    
    if Engine.editor_hint:
        update()
    

