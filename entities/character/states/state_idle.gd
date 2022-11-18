class_name IdleState extends CharacterState

func on_update(delta, fsm):

	character._friction(delta)

	var x = character.input.get_axis_x()
	if abs(character.velocity.x) < character._phys.WALK_MAX_SPEED and abs(round(x)) == 1:
		character.action_dash()
