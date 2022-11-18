extends Enemy

var hit_tween: Tween

var highest: float = 0.0

func _ready():
	super()

func reset():
	super()
	velocity = Vector2.ZERO

func _physics_process(delta):

	$pivot.rotation = -velocity.x * 0.001

	# apply gravity
	velocity.y += 1000 * delta
	velocity.x *= 0.999

	# move body
	var old_vel = velocity
	move_and_slide()

	# calculate bounce
	var col = get_last_slide_collision()
	if col:
		velocity = old_vel.bounce(col.get_normal()) * Vector2(0.9, 0.5)

	# check for new highest
	if global_position.y - 256 < highest:
		highest = global_position.y - 256
		$pivot/label.text = "%.1f m" % -(highest / 64.0)

func hurt(from, _dmg = 1):

	velocity = from.position.direction_to($sprite.global_position) * 1000
	velocity.y = -abs(velocity.y)

	if hit_tween: hit_tween.kill()

	hit_tween = create_tween().set_parallel(true)
	$sprite.scale.y = 0.7
	$sprite.modulate.a = 0.1
	hit_tween.tween_property($sprite, "scale:y", 1, 0.25).set_ease(Tween.EASE_OUT)
	hit_tween.tween_property($sprite, "modulate:a", 1, 0.1)
