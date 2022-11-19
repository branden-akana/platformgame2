extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
    pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
    var input_vector = Vector2.ZERO
    input_vector.x = Input.get_action_strength("key_right") - Input.get_action_strength("key_left")
    input_vector.y = Input.get_action_strength("key_down") - Input.get_action_strength("key_up")
    $"stick/dot".position = Game.get_player().input.axis * 20
    $"stick/dot_2".position = Game.get_player().input.last_axis * 20
    
    if Input.is_action_pressed("key_jump"):
        $jump.modulate.a = 1
    else:
        $jump.modulate.a = 0.1

    if Input.is_action_pressed("grapple"):
        $attack.modulate.a = 1
    else:
        $attack.modulate.a = 0.1
        
    if Input.is_action_pressed("key_dodge"):
        $dash.modulate.a = 1
    else:
        $dash.modulate.a = 0.1
        
    if Input.is_action_pressed("reset"):
        $reset.modulate.a = 1
    else:
        $reset.modulate.a = 0.1

