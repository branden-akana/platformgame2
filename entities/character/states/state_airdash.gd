extends CharacterState
class_name AirdashState

var airdash_dir: Vector2 = Vector2.ZERO

var particles = null

var b_grounded_airdash: bool = false


func can_start(character) -> bool:
	var axis = character.input.get_axis().round().normalized()
	if axis.is_equal_approx(Vector2.ZERO):
		return false
	return true


func on_start(state_from, fsm):

	# limit to 8 directions
	var axis = character.input.get_axis().round().normalized()
	airdash_dir = Vector2.ZERO

	# determine airdash direction
	character.airdashes_left -= 1
	airdash_dir = Vector2(axis.x, axis.y).normalized();
	#GameState.get_camera().screen_shake(1.0, 0.3)

	# grounded airdashes

	# if character.is_grounded and state_from != CharStateName.JUMPSQUAT:
	#     b_can_land_cancel = false
	# else:
	#     b_can_land_cancel = true

	if character.is_grounded and axis.y < 0:
		character.position.y -= 4
		character.is_grounded = false

	character.b_can_slide = false


func on_update(delta, fsm):

	if not is_current(fsm):
		return

	if tick == 1:
		# delayed start of particles
		particles = Effects.play(Effects.Airdash, character)
		particles.get_node("wave").direction = airdash_dir
		if character.facing == Direction.LEFT:
			particles.get_node("trail").material.set_shader_parameter("flip", true)
		else:
			particles.get_node("trail").material.set_shader_parameter("flip", false)

	# middle of airdashing
	if tick >= 0 and tick <= character._phys.AIRDASH_LENGTH:

		# update airdash speed
		var airdash_speed = max(character._phys.AIRDASH_SPEED, character.velocity.length())
		var t = pow(tick / float(character._phys.AIRDASH_LENGTH), 2)
		character.velocity = (airdash_dir * lerpf(
			airdash_speed, character._phys.AIRDASH_SPEED_END, t
		))

	# end of airdashing
	if tick > character._phys.AIRDASH_LENGTH or character.is_grounded:

		# if is_instance_valid(particles):
		# 	particles.emitting = false

		if character.is_grounded:
			character.velocity.y = 0
			# fsm.goto_grounded()
			character.action_neutral()
		else:
			character.action_airborne()


	character.fix_incoming_collisions(delta, 32)


func on_end(state_to, fsm):

	character.b_can_slide = true
	# if is_instance_valid(particles):
	# 	particles.emitting = false
