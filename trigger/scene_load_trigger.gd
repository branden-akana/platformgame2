#================================================================================
# SceneLoadTrigger
#
# A 2D area that triggers loading a different level.
#================================================================================

class_name SceneLoadTrigger
extends Area2D


@export var to_level: PackedScene
@export var size: Vector2 = Vector2(2, 2) :
	get:
		return size
	set(new_size):
		size = new_size
		if ready:
			$collision.position = (size * 16)
			$collision.shape.extents = (size * 16)
			queue_redraw()

func _ready():
	# create a new rectangle shape for the collision
	# this is to ensure individual zones can have different sized shapes
	$collision.shape = RectangleShape2D.new()

	connect("body_entered",Callable(self,"on_body_entered"))

	size = size

func _process(_delta):
	if Engine.is_editor_hint():
		# update the position and content of the text
		$spritetext.position = $collision.position + Vector2($collision.shape.extents.x, 0)
		$spritetext.text = to_level.resource_path.split("/")[-1]
		queue_redraw()

func on_body_entered(body):
	if body is PlayerCharacter:
		GameState.load_scene(to_level)

func _draw():
	if Engine.is_editor_hint():
		Util.draw_zone(self, Color(0.0, 1.0, 0.0))  # green

