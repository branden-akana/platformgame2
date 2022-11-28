extends ParticleGroup


@export @onready var texture: Texture :
	get:
		return $afterimage.texture
	set(value):
		$afterimage.texture = value


func _ready():
	var player = get_parent()
	if player is Character:

		var model_viewport = player._model.get_model_viewport()
		texture = ImageTexture.create_from_image(model_viewport.get_texture().get_image())
		top_level = true

		position = player.interpolated_position
		var dir = player.velocity.normalized()

		# $splash.gravity = -player.velocity.normalized() * 2000
		$splash.rotation = dir.angle() + deg_to_rad(90)

	else:
		queue_free()


func _process(_delta):
	var player = get_parent()
	# position = player.interpolated_position
	position = player.position
