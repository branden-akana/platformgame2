extends CharacterState
class_name RunningState


func on_update(delta, character, fsm):
    if is_current_state(fsm):

        #snap_down_to_ground(delta, 16)
        #snap_up_to_ground(delta, 16)

        character._acceleration(delta)

        if not character.is_facing_forward():
            return CharStateName.IDLE


func on_end(state_to, character, fsm):
    # if state_to == CharStateName.IDLE:
        # character.velocity.x = clamp(character.velocity.x, -character.RUNNING_STOP_SPEED, character.RUNNING_STOP_SPEED)
    # print("stopped running")
    character.emit_signal("stop_walking")
