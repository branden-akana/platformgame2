extends Node2D


var total = 0
var alive = 0
var dead = 0

const SPACING = 64

func _physics_process(_delta):
    if not Engine.is_editor_hint():
        var room = GameState.current_room
        
        if is_instance_valid(room):
            
            total = len(room.get_enemies())
            alive = len(room.get_alive_enemies())
            dead = total - alive
            
            queue_redraw()
    else:
        alive = 2
        dead = 2
        queue_redraw()

func _draw():
    
    var x = -get_origin(total)
    
    for _i in range(dead):
        # draw_circle(Vector2(x, 0), 8, Color(0.0, 0.0, 0.0, 0.6))
        draw_circle(Vector2(x, 0), 4, Color(1.0, 1.0, 1.0, 0.6))
        x += SPACING
        
    for _i in range(alive):
        # draw_circle(Vector2(x, 0), 14, Color(0.0, 0.0, 0.0, 1.0))
        draw_circle(Vector2(x, 0), 10, Color(1.0, 1.0, 1.0, 1.0))

        x += SPACING
        
func get_width(total):
    return total * SPACING
    
func get_origin(_total):
    return 0
    # return (get_width(total) / 2.0) - (SPACING / 2.0)
    

    
    
        
