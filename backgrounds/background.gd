class_name Background
extends Node2D

# factor of background movement to camera movement
@export (float) var parallax = 0.5

@onready var origin: Vector2 = position  # reference to original position

func _process(delta):
    if Game.has_method("get_camera_3d"):
        position = origin + Game.get_camera_3d().focus * parallax

