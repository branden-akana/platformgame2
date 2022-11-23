class_name IdleState extends CharacterState

func on_update(delta, fsm):

	character._friction(delta)

	if (character.input.holding_left() or 
	character.input.holding_right()):
		character.action_dash()