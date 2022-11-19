extends Node2D


func _process(_delta):
    queue_redraw()
    
func _draw():
    if Engine.is_editor_hint():
        var color = Color(1.0, 1.0, 1.0)
        var points = PackedVector2Array([Vector2(0, 16), Vector2(-16, -16), Vector2(16, -16)])
        draw_polyline(points, color, 4)
