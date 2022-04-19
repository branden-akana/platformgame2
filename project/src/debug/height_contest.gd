extends Node2D

var max_height = 0

func _physics_process(delta):
    var height = -(Game.get_player().global_position.y - global_position.y)
    if height > max_height:
        max_height = height
        
    $polygon_2d.position.y = -max_height
    $spritetext.position.y = -max_height
    $spritetext.text = "%0.3fu" % max_height
