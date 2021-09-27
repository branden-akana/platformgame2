extends Area2D

onready var sprite: Polygon2D = $sprite

const HIT_SHIFT_AMT = 1000
const HIT_ELASTICITY = 0.5

const HIT_COLOR_LENGTH = 0.2

var health = 100

var origin: Vector2

var hit_direction: Vector2
var hit_shift: Vector2  # position shift from being hit
var hit_elasticity: float = 0.0


var color_blend: float = 0.0

func _ready():
    origin = position
    self.connect("area_entered", self, "on_area_enter")
    
func _process(delta):
    sprite.global_rotation += delta

    if hit_direction and hit_elasticity > 0.0:
        hit_shift += hit_direction * delta * HIT_SHIFT_AMT
        hit_elasticity -= delta

    $sprite.position = lerp(Vector2.ZERO, hit_shift, ease(hit_elasticity / HIT_ELASTICITY, 3))

    if color_blend > 0.0:
        sprite.color = lerp(Color(0.45, 0.45, 0.45), Color(0.6, 0.6, 0.6), color_blend / HIT_COLOR_LENGTH)
        color_blend -= delta

    if health > 0:
        sprite.color = Color(0.45, 0.45, 0.45)
    else:
        sprite.color = Color(0.2, 0.2, 0.2)

func on_area_enter(area):
    var no_damage = area.get_parent().no_damage
    if not no_damage:
        hit_shift = Vector2.ZERO
        hit_direction = area.get_parent().position.direction_to(position)
        hit_elasticity = HIT_ELASTICITY
        color_blend = HIT_COLOR_LENGTH
        health = 0

