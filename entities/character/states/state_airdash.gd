extends CharacterState
class_name AirdashState

var airdash_dir: Vector2 = Vector2.ZERO

var particles = null

var is_grounded_airdash: bool = false


func on_start(state_from, _fsm, _args):

	character.input.eat_input("jump")

	# limit to 8 directions
	var axis = character.input.get_axis().round().normalized()
	airdash_dir = Vector2.ZERO

	# determine airdash direction
	character.consume_airdash()
	airdash_dir = Vector2(axis.x, axis.y).normalized();
	#GameState.get_camera().screen_shake(1.0, 0.3)

	# grounded airdashes
	if not character.is_grounded or state_from == CharStateName.JUMPSQUAT:
		is_grounded_airdash = false
		# _allow(CharacterActions.LAND)
	else:
		is_grounded_airdash = true

	character.b_can_slide = false
	

func on_end(state_to, _fsm):

	character.b_can_slide = true
	_disallow(CharacterActions.LAND)

	# if state_to in [CharStateName.ATT_FORWARD, CharStateName.ATT_DAIR, CharStateName.ATT_UAIR]:
	character.velocity = (character.velocity.normalized() * clamp(character.velocity.length(), 0.0, character._phys.AIRDASH_SPEED_CANCEL))

	if is_instance_valid(particles) and state_to == CharStateName.IDLE:
		particles.emitting = false


func on_update(_delta, _fsm):

	if tick == 0:
		particles = FXEmitter.play(FXEmitter.Airdash, character)
		particles.top_level = true

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

	if not is_grounded_airdash and character.is_grounded:
		character.action_neutral()


	character.fix_incoming_collisions(_delta, character._phys.AIRDASH_WAVELAND_MARGIN)

