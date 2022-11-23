class_name Background
extends Node2D

# factor of background movement to camera movement
@export var parallax : float

@onready var origin: Vector2 = position  # reference to original position

func _process(_delta):
	if GameState.has_method("get_camera"):
		position = origin + GameState.get_camera().focus * parallax

