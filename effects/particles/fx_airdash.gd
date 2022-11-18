extends ParticleGroup


@export @onready var texture: Texture :
	get:
		return $trail.texture
	set(value):
		$trail.texture = value


func _ready():
	var player = get_node(Constants.PATH_PLAYER)
	var model_viewport = player._model.get_model_viewport()
	texture = ImageTexture.create_from_image(model_viewport.get_texture().get_image())
	top_level = true

	position = player.interpolated_position - player.position

	# $splash.gravity = -player.velocity.normalized() * 2000
	$splash.direction = player.velocity.normalized()
	# $wave_2.gravity = -player.velocity.normalized() * 1000


func _process(_delta):
	var player = get_node(Constants.PATH_PLAYER)
	position = player.interpolated_position - player.position
