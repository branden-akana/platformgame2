extends Area2D
class_name CameraZone
tool

export (Vector2) var region_size = Vector2(20, 11.25) setget set_region_size
export var palette_idx = 0

onready var collision: CollisionShape2D = $collision

func set_region_size(size):
    region_size = size
    $collision.shape = RectangleShape2D.new()
    $collision.shape.extents = (region_size * 64 - Vector2(32, 32)) / 2
    $collision.position = region_size * 64 / 2
    update()

# debug visuals
func _draw():
    if Engine.editor_hint:
        var color = Color(1.0, 1.0, 1.0)
        draw_rect(Rect2(Vector2(0, 0), region_size * 64), color, false, 4.0)
        draw_rect(Rect2(Vector2(16, 16), (region_size * 64) - Vector2(32, 32)), color, false, 4.0)

