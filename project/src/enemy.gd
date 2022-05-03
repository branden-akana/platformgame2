extends Area2D
class_name Enemy
tool

const HIT_SHIFT_AMT = 1000
const HIT_ELASTICITY = 0.5

const HIT_COLOR_LENGTH = 0.2

export (int) var max_health = 1 setget set_max_health

onready var health = max_health

var origin: Vector2

var hit_direction: Vector2 = Vector2.ZERO
var hit_shift: Vector2 = Vector2.ZERO # position shift from being hit
var hit_elasticity: float = 0.0

var color_blend: float = 0.0

# flags

var is_alive = true
var is_visible_when_dead = false

# children

onready var sprite: Polygon2D = $sprite
onready var tween = Tween.new()

func _ready():
    add_child(tween)
    reset()
    
func _process(delta):
    if not is_instance_valid(sprite):
        return

    if Engine.editor_hint:
        return
        
    sprite.global_rotation += delta

    if hit_direction and hit_elasticity > 0.0:
        hit_shift += hit_direction * delta * HIT_SHIFT_AMT
        hit_elasticity -= delta

    # shift sprite in hit direction
    sprite.position = lerp(Vector2.ZERO, hit_shift, ease(hit_elasticity / HIT_ELASTICITY, 3))

func set_max_health(max_hp):
    max_health = max_hp
    reset()
    
func reset():
    health = max_health
    is_alive = true
    modulate.a = 1.0

    if is_instance_valid(sprite):
        update_color()

func get_hp_color(hp):
    match(hp):
        0:
            if is_visible_when_dead:
                return Color(0.7, 0.1, 0.7, 0.5)
            else:
                return Color(0.3, 0.1, 0.3, 0.0)
        1:
            return Color(0.7, 0.1, 0.7)
        2:
            return Color(1.0, 0.1, 1.0)
        _:
            return Color(1.0, 1.1, 1.0)

func update_color():
    sprite.color = get_hp_color(health)

func hurt(from, dmg = 1):
    hit_shift = Vector2.ZERO
    hit_direction = from.position.direction_to(position)
    hit_elasticity = HIT_ELASTICITY
    color_blend = HIT_COLOR_LENGTH

    health = max(0, health - dmg)
        
    if health == 0 and is_alive:
        is_alive = false

    # fade enemy color
    if !is_alive:
        tween.interpolate_property(self, "modulate:a", 1.0, 0.0, 0.2)

    tween.interpolate_property(sprite, "color",
        get_hp_color(health + 1), get_hp_color(health), 0.2
    )
    tween.start()

# func on_area_enter(area):
#     var no_damage = area.get_parent().no_damage
#     if not no_damage:
#         hit_shift = Vector2.ZERO
#         hit_direction = area.get_parent().position.direction_to(position)
#         hit_elasticity = HIT_ELASTICITY
#         color_blend = HIT_COLOR_LENGTH
#         health = 0

