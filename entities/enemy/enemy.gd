extends Area2D
class_name Enemy


const HIT_SHIFT_AMT = 1000
const HIT_ELASTICITY = 0.5

const HIT_COLOR_LENGTH = 0.2

@export var max_health: int = 1 :
	get:
		return max_health # TODOConverter40 Non existent get function 
	set(max_hp):
		max_health = max_hp
		reset()
	

@onready var health = max_health

var origin: Vector2

var hit_direction: Vector2 = Vector2.ZERO
var hit_shift: Vector2 = Vector2.ZERO # position shift from being hit
var hit_elasticity: float = 0.0

var color_blend: float = 0.0

# flags

var is_alive = true
var is_visible_when_dead = false

# children

@onready var sprite: Polygon2D = $sprite
var tween: Tween

func _ready():
	reset()
	
func _process(delta):
	if not is_instance_valid(sprite):
		return

	if Engine.is_editor_hint():
		return
		
	sprite.global_rotation += delta

	if hit_direction != Vector2.ZERO and hit_elasticity > 0.0:
		hit_shift += hit_direction * delta * HIT_SHIFT_AMT
		hit_elasticity -= delta

	# shift sprite in hit direction
	sprite.position = lerp(Vector2.ZERO, hit_shift, ease(hit_elasticity / HIT_ELASTICITY, 3))

func reset():
	health = max_health
	is_alive = true
	modulate.a = 1.0

	if is_instance_valid(sprite):
		update_color()

func get_hp_color(hp):
	match(hp):
		0:
			if GameState.is_practice_mode_enabled:
				return Color(1.0, 1.0, 1.0, 0.5)
			else:
				return Color(0.3, 0.1, 0.3, 0.0)
		1:
			return Color(1.0, 1.0, 0.5)
		2:
			return Color(1.0, 1.0, 1.0)
		3, _:
			return Color(1.0, 0.0, 1.0)

func update_color():
	modulate = get_hp_color(health)
	update_size()

func update_size():
	match(health):
		0, 1:
			$sprite.scale = Vector2(1.5, 1.5)
		2:
			$sprite.scale = Vector2(2, 2)
		3, _:
			$sprite.scale = Vector2(2.5, 2.5)

func hurt(from, dmg = 1):
	hit_shift = Vector2.ZERO
	hit_direction = from.position.direction_to(position)
	hit_elasticity = HIT_ELASTICITY
	color_blend = HIT_COLOR_LENGTH

	health = max(0, health - dmg)
		
	if health == 0 and is_alive:
		is_alive = false

	if tween: tween.kill()
	tween = create_tween().set_parallel(true)

	# fade enemy color
	if !is_alive and not is_visible_when_dead:
		modulate.a = 1.0
		tween.tween_property(self, "modulate:a", 0.0, 0.2)

	modulate = get_hp_color(health + 1)
	tween.tween_property(self, "modulate", get_hp_color(health), 0.2)
	
	update_size()


# func on_area_enter(area):
#     var no_damage = area.get_parent().no_damage
#     if not no_damage:
#         hit_shift = Vector2.ZERO
#         hit_direction = area.get_parent().position.direction_to(position)
#         hit_elasticity = HIT_ELASTICITY
#         color_blend = HIT_COLOR_LENGTH
#         health = 0

