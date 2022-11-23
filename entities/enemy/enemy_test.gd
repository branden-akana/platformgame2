extends Enemy

const HIT_SHIFT_AMT = 1000
const HIT_ELASTICITY = 0.5
const HIT_COLOR_LENGTH = 0.2


@onready var sprite: Polygon2D = $sprite

var tween: Tween

var hit_direction: Vector2 = Vector2.ZERO
var hit_shift: Vector2 = Vector2.ZERO # position shift from being hit
var hit_elasticity: float = 0.0

var color_blend: float = 0.0

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

func reset() -> void:
	super.reset()

	modulate.a = 1.0
	if is_instance_valid(sprite):
		update_color()

func hurt(from, dmg = 1) -> void:
	super.hurt(from, dmg)

	hit_shift = Vector2.ZERO
	hit_direction = from.position.direction_to(position)
	hit_elasticity = HIT_ELASTICITY
	color_blend = HIT_COLOR_LENGTH

	if tween: tween.kill()
	tween = create_tween().set_parallel(true)

	# fade enemy color
	if !is_alive and not is_visible_when_dead:
		modulate.a = 1.0
		tween.tween_property(self, "modulate:a", 0.0, 0.2)

	modulate = get_hp_color(health + 1)
	tween.tween_property(self, "modulate", get_hp_color(health), 0.2)
	
	update_size()