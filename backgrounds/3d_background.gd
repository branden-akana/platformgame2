extends Sprite2D


@export var scroll_rate: float = 1.0
@export var parallax: float = 0.5

@onready var origin: Vector2 = position

var camera

func _ready():
	top_level = true

func _process(delta):

	if not Engine.is_editor_hint() and GameState.is_inside_tree():
		camera = GameState.get_camera()

	var box_1 = $viewport/spatial/csg_box
	var box_2 = $viewport/spatial/csg_box_2

	var z = scroll_rate * delta
	if camera:
		var x = origin.x + camera.focus.x * parallax * 0.0005
		position = origin + camera.focus

		box_1.material.uv1_offset.x = fmod(-x, 1.0)
		box_2.material.uv1_offset.x = fmod(-x, 1.0)

	box_1.material.uv1_offset.z = fmod(box_1.material.uv1_offset.z + z, 1.0)
	box_2.material.uv1_offset.z = fmod(box_2.material.uv1_offset.z + z, 1.0)

	
	
	
