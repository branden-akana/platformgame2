extends Area2D
class_name DoorTrigger

export (NodePath) var door_path

func _ready():
    connect("body_entered", self, "on_trigger")

func _draw():
    var door = get_node(door_path)
    if Engine.editor_hint and door:
        draw_line(position, door.position, Color(0.0, 1.0, 0.0), 4)
    
func on_trigger(_body):
    var door = get_node(door_path)
    if door:
        door.close_door(true)
        yield(door, "door_closed")
        #Game.set_start_point(2)
