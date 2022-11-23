extends CharacterState
class_name AirborneState


func on_update(delta, _fsm):

    character._acceleration(delta)
    character._friction(delta)

    if character.position.y < character.airborne_height:
        character.airborne_height = character.position.y
