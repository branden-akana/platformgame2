extends Node2D


func _process(delta):
    if Game.game_paused:
        $spritetext.modulate.a = 0.25
    else:
        $spritetext.modulate.a = 0
