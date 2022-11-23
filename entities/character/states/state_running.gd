extends CharacterState
class_name RunningState


func on_update(delta, fsm):
    if is_current(fsm):

        #snap_down_to_ground(delta, 16)
        #snap_up_to_ground(delta, 16)

        character._acceleration(delta)

        if not character.is_facing_forward():
            character.action_neutral()