extends Node2D


func _process(delta):
    if GameState.is_paused():
        $spritetext.modulate.a = 0.25
    else:
        $spritetext.modulate.a = 0
