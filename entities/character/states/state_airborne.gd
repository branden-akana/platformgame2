extends CharacterState
class_name AirborneState

func on_start(state_from, character, fsm):
    character.set_grounded(false)
    character.airborne_height = character.position.y
    character.b_gravity_enabled = true

func on_update(delta, character, fsm):

    character._acceleration(delta)
    character._friction(delta)

    if character.position.y < character.airborne_height:
        character.airborne_height = character.position.y
