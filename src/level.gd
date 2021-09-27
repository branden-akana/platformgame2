extends TileMap
class_name Level
tool

export (Vector2) var start_point

func _draw():
    if Engine.editor_hint:
        draw_circle(start_point / scale, 4, Color(0.5, 0.5, 0.5))
        
func _process(delta):
    if Engine.editor_hint:
        update()


