extends CharacterState
class_name JumpsquatState


func on_update(delta, character, fsm):
    if tick >= character.JUMPSQUAT_LENGTH:
        # shorthop or fullhop
        var jump_factor = 1.0 if character.holding_jump() else 0.6
        character.action_jump(jump_factor)

