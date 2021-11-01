extends Area2D
class_name Enemy

const HIT_SHIFT_AMT = 1000
const HIT_ELASTICITY = 0.5

const HIT_COLOR_LENGTH = 0.2

var health = 100

var origin: Vector2

var hit_direction: Vector2
var hit_shift: Vector2  # position shift from being hit
var hit_elasticity: float = 0.0

var color_blend: float = 0.0

var is_alive = true

# children

onready var sprite: Polygon2D = $sprite
onready var tween = Tween.new()
onready var real_position = $sprite.global_position

func _ready():
    origin = position
    # self.connect("area_entered", self, "on_area_enter")
    
    set_as_toplevel(true)
    position = real_position
    Game.reparent_to_fg2(sprite)

    add_child(tween)
    
func _process(delta):
    if not is_instance_valid(sprite):
        return
        
    sprite.global_rotation += delta

    if hit_direction and hit_elasticity > 0.0:
        hit_shift += hit_direction * delta * HIT_SHIFT_AMT
        hit_elasticity -= delta

    # shift sprite in hit direction
    sprite.position = global_position + lerp(Vector2.ZERO, hit_shift, ease(hit_elasticity / HIT_ELASTICITY, 3))

    # fade sprite out when killed
    if health == 0 and is_alive and not tween.is_active():
        is_alive = false
        tween.interpolate_property(sprite, "color",
            Color(0.7, 0.7, 0.7), Color(0.2, 0.2, 0.2, 0.0), 0.5
        )
        tween.start()
    
func reset():
    if sprite:
        sprite.color = Color(0.7, 0.7, 0.7)
    health = 100
    is_alive = true

func damage(from, dmg = 1):
    hit_shift = Vector2.ZERO
    hit_direction = from.position.direction_to(position)
    hit_elasticity = HIT_ELASTICITY
    color_blend = HIT_COLOR_LENGTH
    health = 0

# func on_area_enter(area):
#     var no_damage = area.get_parent().no_damage
#     if not no_damage:
#         hit_shift = Vector2.ZERO
#         hit_direction = area.get_parent().position.direction_to(position)
#         hit_elasticity = HIT_ELASTICITY
#         color_blend = HIT_COLOR_LENGTH
#         health = 0

