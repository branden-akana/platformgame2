extends CharacterState
class_name AirdashState

var airdash_dir: Vector2 = Vector2.ZERO

var particles = null

var b_grounded_airdash: bool = false


func on_start(state_from, _fsm):

	# limit to 8 directions
	var axis = character.input.get_axis().round().normalized()
	airdash_dir = Vector2.ZERO

	# determine airdash direction
	character.consume_airdash()
	airdash_dir = Vector2(axis.x, axis.y).normalized();
	#GameState.get_camera().screen_shake(1.0, 0.3)

	# grounded airdashes

	# if character.is_grounded and state_from != CharStateName.JUMPSQUAT:
	#     b_can_land_cancel = false
	# else:
	#     b_can_land_cancel = true

	print("start airdash from %s" % state_from)
	if not character.is_grounded:
		_allow(CharacterActions.LAND)

	character.b_can_slide = false
	

func on_end(_state_to, _fsm):

	character.b_can_slide = true
	_disallow(CharacterActions.LAND)

	# if state_to in [CharStateName.ATT_FORWARD, CharStateName.ATT_DAIR, CharStateName.ATT_UAIR]:
	character.velocity = (character.velocity.normalized() * clamp(character.velocity.length(), 0.0, character._phys.AIRDASH_SPEED_CANCEL))

	if is_instance_valid(particles):
		particles.emitting = false


func on_update(_delta, fsm):

	if not is_current(fsm):
		return

	if tick == 1:
		# delayed start of particles
		particles = FXEmitter.play(FXEmitter.Airdash, character)
		particles.top_level = true
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
	if tick > character._phys.AIRDASH_LENGTH:

		if character.is_grounded:
			character.velocity.y = 0
			# fsm.goto_grounded()
			character.action_neutral()
		else:
			character.action_airborne()


	character.fix_incoming_collisions(_delta, character._phys.AIRDASH_WAVELAND_MARGIN)

