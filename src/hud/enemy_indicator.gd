extends Node2D

var total = 0
var alive = 0
var dead = 0

const SPACING = 32

func _physics_process(delta):
    var room = Game.current_room
    
    if is_instance_valid(room):
        
        total = len(room.get_enemies())
        alive = len(room.get_alive_enemies())
        dead = total - alive
        
        update()

func _draw():
    
    var x = -get_origin(total)
    
    for _i in range(dead):
        draw_circle(Vector2(x, 0), 5, Color(1.0, 1.0, 1.0, 0.2))
        x += SPACING
        
    for _i in range(alive):
        draw_circle(Vector2(x, 0), 14, Color(0.0, 0.0, 0.0, 0.6))
        draw_circle(Vector2(x, 0), 10, Color(1.0, 1.0, 1.0, 0.3))

        x += SPACING
        
func get_width(total):
    return total * SPACING
    
func get_origin(total):
    return (get_width(total) / 2) - (SPACING / 2)
    

    
    
        
