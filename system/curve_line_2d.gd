## Curve Line 2D
## A Line2D that draws a Curve2D.
@tool
extends Line2D

## amount of points to use as a percentage of the total points in the curve
@export var amount: float = 1.0;

## the max amount of points to use
@export var max_points: int = 20;

## the max width of the line. the actual width will scale with the amount of points used
@export var max_width: float = 10;

func _process(_delta):
	if $path_2d:
		var curve_points = $path_2d.curve.get_baked_points()
		var end = floor(curve_points.size() * amount)
		var start = max(0, end - max_points)
		width = (end - start) / curve_points.size() * max_width
		points = curve_points.slice(max(0, end - max_points), end)
