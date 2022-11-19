extends Enemy

var hit_tween: Tween

var highest: float = 0.0
var hits: int = 0
var most_hits: int = 0

var idle_time: float = 0.0
var spinning: bool = false
var tilt_tween: Tween

func _ready():
	super()

func reset():
	super()
	velocity = Vector2.ZERO

func _physics_process(delta):

	var cam = GameState.get_camera()

	# if cam.is_in_view(position):
	# 	$canvas_layer/arrow.visible = true
	# else:
	$canvas_layer/arrow.visible = true
	$canvas_layer/arrow.position.x = cam.world_to_view(position).x
	var dist = clamp((640.0 - abs(cam.focus.y - position.y)) / 640.0, 0, 1.0)
	$canvas_layer/arrow.scale.x = dist * 4.0
	$canvas_layer/arrow.color.a = dist

	if velocity.y > -3:
		idle_time += delta
	else:
		idle_time = 0

	if hits >= 5: spinning = true
	if idle_time >= 2: spinning = false

	if spinning:
		$sprite/eyes_1.visible = false
		$sprite/eyes_2.visible = true
		$sprite.rotate(-velocity.x * 0.001)
	else:
		$sprite/eyes_1.visible = true
		$sprite/eyes_2.visible = false

		if tilt_tween: tilt_tween.kill()
		tilt_tween = create_tween()
		tilt_tween.tween_property($sprite, "rotation", -velocity.x * 0.001, 0.2)

	$pivot.rotation = -velocity.x * 0.001

	# apply gravity
	velocity.y += 500 * delta
	velocity.x *= 0.999

	# move body
	var old_vel = velocity
	move_and_slide()
	velocity = get_real_velocity()

	# calculate bounce
	var col = get_last_slide_collision()
	if col:
		if col.get_normal().is_equal_approx(Vector2.UP):
			if hits > most_hits: most_hits = hits
			hits = 0
			$pivot/hits.text = ""
			$canvas_layer/most_hits.text = "%d hits" % most_hits
			$canvas_group/particles.emitting = false
		velocity = old_vel.bounce(col.get_normal()) * Vector2(0.9, 0.5)

	# check for new highest
	if global_position.y < highest:
		highest = global_position.y
		$canvas_layer/label.text = "%.1f m" % -(highest / 20.0)


func hurt(from, _dmg = 1):

	hits += 1
	$pivot/hits.text = str(hits)

	if hits == 5: $canvas_group/particles.emitting = true

	velocity = from.position.direction_to($sprite.global_position) * (300 + 25 * hits) * Vector2(0.7, 1)
	velocity.y = -abs(velocity.y)

	if hit_tween: hit_tween.kill()

	hit_tween = create_tween().set_parallel(true)
	$sprite.scale.y = 0.7
	$sprite.modulate.a = 0.1
	hit_tween.tween_property($sprite, "scale:y", 1, 0.25).set_ease(Tween.EASE_OUT)
	hit_tween.tween_property($sprite, "modulate:a", 1, 0.1)

	from.restore_jumps()
