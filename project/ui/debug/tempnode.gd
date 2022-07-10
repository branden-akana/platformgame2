extends Node2D

# Delete itself as soon as game starts
func _ready():
    queue_free()
