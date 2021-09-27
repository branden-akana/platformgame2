extends ColorRect


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var origin = Vector2()

# Called when the node enters the scene tree for the first time.
func _ready():
	origin = rect_position


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var input_vector = Vector2(0, 0)
	input_vector.x = Input.get_action_strength("key_right") - Input.get_action_strength("key_left")
	input_vector.y = Input.get_action_strength("key_down") - Input.get_action_strength("key_up")

	rect_position = origin + (input_vector * 20)
