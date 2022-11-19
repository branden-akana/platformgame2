#================================================================================
# DoorTrigger
#
# A 2D area that triggers opening a door.
#================================================================================

class_name DoorTrigger
extends Area2D

@export var door_path: NodePath

func _ready():
    connect("body_entered",Callable(self,"on_trigger"))

func _draw():
    var door = get_node(door_path)
    if Engine.is_editor_hint() and door:
        draw_line(position, door.position, Color(0.0, 1.0, 0.0), 4)
    
func on_trigger(_body):
    var door = get_node(door_path)
    if door:
        door.close_door(true)
        await door.door_closed
        #GameState.set_start_point(2)
