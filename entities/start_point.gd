extends Node2D
@tool

func _process(delta):
    update()
    
func _draw():
    if Engine.editor_hint:
        var color = Color(1.0, 1.0, 1.0)
        var points = PackedVector2Array([Vector2(0, 16), Vector2(-16, -16), Vector2(16, -16)])
        draw_polyline(points, color, 4)
