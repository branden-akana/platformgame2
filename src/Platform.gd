tool
extends StaticBody2D

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

export (int) var width : int = 200

# Called when the node enters the scene tree for the first time.
func _ready():
    _update_shape()

func _process(delta):
    _update_shape()

func _update_shape():
    if Engine.editor_hint:
        var points = PoolVector2Array([
            Vector2(0, 0),
            Vector2(width, 0),
            Vector2(width, 4),
            Vector2(0, 4)
        ])
        $"Polygon2D".material = load("res://PlatformMaterial.tres")
        $"Polygon2D".set_polygon(points)
        $"CollisionPolygon2D".set_polygon(points)
        $"CollisionPolygon2D".one_way_collision = true
        $"CollisionPolygon2D".one_way_collision_margin = 8

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
