#================================================================================
# DoorTrigger
#
# A 2D area that triggers opening a door.
#================================================================================

class_name DoorTrigger
extends Area2D

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
