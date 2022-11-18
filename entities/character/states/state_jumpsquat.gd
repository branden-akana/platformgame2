class_name JumpsquatState extends CharacterState


func on_update(delta, fsm):
	if tick >= character._phys.JUMPSQUAT_LENGTH:
		# shorthop or fullhop
		var jump_factor = 1.0 if character.input.holding_jump() else 0.6
		character.action_jump(jump_factor)

