#================================================================================
# Area3D Title Trigger
#
# When a player enters this area, show a level title effect.
#================================================================================
extends Area2D
@tool

@export var title = "unnamed area"
@export (Vector2) var extents = Vector2(8, 2) :
	get:
		return extents # TODOConverter40 Copy here content of get_extents
	set(mod_value):
		mod_value  # TODOConverter40 Copy here content of set_extents

func _ready():
    connect("body_entered",Callable(self,"on_body_entered"))
    connect("body_exited",Callable(self,"on_body_exited"))
    
func set_extents(new_extents):
    extents = new_extents
    $collision_shape_2d.shape.extents = extents * 32
    
func get_extents():
    return extents

func on_body_entered(body):
    if body is PlayerRunner:
        print("showing title")
        HUD.lbox_in(0.5)
        HUD.area_title_in(title, 0.5)

func on_body_exited(body):
    if body is PlayerRunner:
        print("unshowing title")
        HUD.lbox_out(0.5)
        HUD.area_title_out(0.5)
