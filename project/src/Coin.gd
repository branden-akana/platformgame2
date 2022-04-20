extends KinematicBody2D
class_name Coin


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var init_velocity = Vector2.ZERO
var velocity = Vector2.ZERO
var hit_floor = false

var airtime = 0.0

# Called when the node enters the scene tree for the first time.
func _ready():
    pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#    pass

func launch(direction):
    init_velocity = direction

func set_color(color):
    $"Polygon2D".color = color

func get_color():
    return $"Polygon2D".color

func shoot_left():
    launch(Vector2(-3, -1).normalized())

func shoot_right():
    launch(Vector2(3, -1).normalized())

func shoot_up():
    launch(Vector2(0, -0.65))

func shoot_down():
    launch(Vector2(0, 1))

func _physics_process(delta):

    var post_velocity = velocity
    post_velocity.x = clamp(velocity.x, -8, 8)

    if !hit_floor:
        post_velocity.y = min(400, post_velocity.y + (40 * delta))
        rotation_degrees += 360 * delta * 2
    else:
        post_velocity = Vector2.ZERO

    velocity = lerp((init_velocity * 16), post_velocity, pow(clamp(airtime / 0.15, 0.0, 1.0), 10))
 
    var collision_info = move_and_collide(velocity)
    if collision_info:
        $"CPUParticles2D".emitting = false
        hit_floor = true

    airtime += delta



