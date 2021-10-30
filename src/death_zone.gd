extends Area2D
tool

export (Vector2) var region_size = Vector2(20, 11.25)

onready var collision: CollisionShape2D = $collision

func _ready():

    collision.shape = RectangleShape2D.new()
    collision.shape.extents = (region_size * 64 - Vector2(32, 32)) / 2
    collision.position = region_size * 64 / 2

    connect("body_entered", self, "on_body_entered")

func get_respawn_point():
    return $"respawn_point".position
    
func on_body_entered(body):

    body.respawn(position + get_respawn_point())
    
# debug visuals

func _draw():
    
    if Engine.editor_hint:
        var color = Color(0.7, 0.0, 0.0)
        draw_rect(Rect2(Vector2(0, 0), region_size * 64), color, false, 4.0)
        draw_rect(Rect2(Vector2(16, 16), (region_size * 64) - Vector2(32, 32)), color, false, 4.0)

        var respawn_point = get_respawn_point()
        draw_arc(respawn_point, 32, 0, 2 * PI, 20, color, 4) 
        draw_line((region_size * 64) / 2, respawn_point, color, 4)
    
func _process(delta):
        update()
    
