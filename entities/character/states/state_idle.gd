class_name IdleState extends CharacterState

func on_update(delta, _fsm):

	character._friction(delta)

	if abs(character.velocity.x) <= 200:

		if character.input.holding_left() and not character.input.holding_right():
			character.action_dash(Direction.LEFT)

		elif character.input.holding_right() and not character.input.holding_left():
			character.action_dash(Direction.RIGHT)