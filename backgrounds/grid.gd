class_name GridBackground extends Node2D
@tool

# factor of background movement to camera movement
@export (float) var parallax = 0.5

@onready var origin: Vector2 = position  # reference to original position

@onready var offset = Vector2(0.0, 0.0)

func _process(delta):
    if Game.has_method("get_camera_3d"):
        position = origin + Game.get_camera_3d().focus

    offset.x = fmod(offset.x + (delta * 10), 64)
    offset.y = fmod(offset.y + (delta * 10), 64)
    $box.texture_offset = ((Game.get_camera_3d().focus * parallax) + offset).round()
    $box_2.texture_offset = (Game.get_camera_3d().focus * parallax * 0.5).round()
