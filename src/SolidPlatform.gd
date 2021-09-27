tool
extends StaticBody2D

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

export (int) var width : int = 200
export (int) var height : int = 50

export (bool) var killbox : bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	_update_shape()

func _process(delta):
	_update_shape()

func _update_shape():
	var points = PoolVector2Array([
		Vector2(0, 0),
		Vector2(width, 0),
		Vector2(width, height),
		Vector2(0, height)
	])
	$"CollisionPolygon2D".set_polygon(points)
	$"Polygon2D".set_polygon(points)
	if killbox:
		$"Polygon2D".material = load("res://DeathColor.tres")
	else:
		$"Polygon2D".material = load("res://SolidColor.tres")


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
