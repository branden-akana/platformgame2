@tool
class_name CurveLine2D extends Line2D


func _ready():
	points = $path.curve.get_baked_points()

func _process(_delta):
	if Engine.is_editor_hint():
		points = $path.curve.get_baked_points()

