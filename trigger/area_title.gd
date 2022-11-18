#================================================================================
# Area3D Title Trigger
#
# When a player enters this area, show a level title effect.
#================================================================================
extends Area2D


@export var title = "unnamed area"
@export var extents: Vector2 = Vector2(8, 2) :
	get:
		return extents
	set(new_extents):
		extents = new_extents
		$collision_shape_2d.shape.extents = extents * 32

func _ready():
	connect("body_entered",Callable(self,"on_body_entered"))
	connect("body_exited",Callable(self,"on_body_exited"))
	
func on_body_entered(body):
	if body is Player:
		print("showing title")
		GameState.get_hud().lbox_in(0.5)
		GameState.get_hud().area_title_in(title, 0.5)

func on_body_exited(body):
	if body is Player:
		print("unshowing title")
		GameState.get_hud().lbox_out(0.5)
		GameState.get_hud().area_title_out(0.5)
