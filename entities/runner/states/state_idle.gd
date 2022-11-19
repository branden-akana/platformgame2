extends CharacterState
class_name IdleState

func on_update(delta, character, fsm):

    character._friction(delta)

    var x = character.get_axis_x()
    if abs(character.velocity.x) < character.WALK_MAX_SPEED and abs(round(x)) == 1:
        return CharStateName.DASH
