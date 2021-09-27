extends CanvasLayer


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

onready var player = $"../Player"

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	# var on = Color(0.90, 0.90, 0.20)
	# var off = Color(1.0, 1.0, 1.0, 0.5)
	# var coins_left = player.coins_left
	# match coins_left:
	# 	0:
	# 		$"Coin1".color = off
	# 		$"Coin2".color = off
	# 		$"Coin3".color = off
	# 	1:
	# 		$"Coin1".color = on
	# 		$"Coin2".color = off
	# 		$"Coin3".color = off
	# 	2:
	# 		$"Coin1".color = on
	# 		$"Coin2".color = on
	# 		$"Coin3".color = off
	# 	3:
	# 		$"Coin1".color = on
	# 		$"Coin2".color = on
	# 		$"Coin3".color = on
