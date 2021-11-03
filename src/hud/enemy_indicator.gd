extends Node2D

var total = 0
var alive = 0
var dead = 0

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
        draw_circle(Vector2(x, 0), 8, Color(1.0, 1.0, 1.0, 0.7))
        x += 48
        
    for _i in range(alive):
        draw_circle(Vector2(x, 0), 14, Color(1.0, 1.0, 1.0, 0.7))
        x += 48
        
func get_width(total):
    return total * 48
    
func get_origin(total):
    return (get_width(total) / 2) - (48 / 2)
    

    
    
        
