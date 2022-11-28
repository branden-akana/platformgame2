extends ParticleGroup


func _ready():
	var player = get_node(Constants.PATH_PLAYER)
	$spark.direction = Vector2(-player.velocity.x / 300.0, -abs(player.velocity.x / 300.0))
