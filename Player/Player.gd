extends KinematicBody2D

const ACCELERATION = 500
const MAX_SPEED = 200
const FRICTION = 800
const DODGE_SPEED = 350

onready var debug_info = $"../HUD/DebugInfo"

enum {
	MOVE,
	DODGE
}

var state = MOVE
var velocity = Vector2.ZERO
var dodge_vector = Vector2.DOWN

func _physics_process(delta):
	match state:
		MOVE:
			move_state(delta)
		DODGE:
			dodge_state(delta)

func move_state(delta):
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_action_strength("key_right") - Input.get_action_strength("key_left")
	input_vector.y = Input.get_action_strength("key_down") - Input.get_action_strength("key_up")
	input_vector = input_vector.normalized()
	
	if input_vector != Vector2.ZERO:
		# apply acceleration
		dodge_vector = input_vector
		velocity += input_vector * ACCELERATION * delta
		velocity = velocity.move_toward(input_vector* MAX_SPEED, ACCELERATION * delta)

	if velocity.length() > MAX_SPEED or input_vector.length() == 0:
		# apply friction
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)

	debug_info.text = "x: %.2f\ny: %.2f\nspeed: %.2f" % [velocity.x, velocity.y, velocity.length()]
	move()
	
	if Input.is_action_just_pressed("key_dodge"):
		state = DODGE

func dodge_state(delta):
	velocity = dodge_vector * DODGE_SPEED
	move()

func move():
	velocity = move_and_slide(velocity)
	dodge_state_finished()

func dodge_state_finished():
	state = MOVE
