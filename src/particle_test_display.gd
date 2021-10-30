extends Node2D

export var ROTATION_SPEED = 10
export var ROTATION_RADIUS = 50
export (PackedScene) var PARTICLES

var particles
var time: float = 0.0

func _ready():
    particles = PARTICLES.instance()
    particles.one_shot = false
    particles.emitting = true
    add_child(particles)

func _physics_process(delta):
    if particles:
        particles.position = Vector2(sin(time * ROTATION_SPEED), cos(time * ROTATION_SPEED)) * ROTATION_RADIUS
        time += delta
