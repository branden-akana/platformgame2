extends CharacterState
class_name RunningState


func on_update(delta, fsm):
    if is_current(fsm):

        #snap_down_to_ground(delta, 16)
        #snap_up_to_ground(delta, 16)

        character._acceleration(delta)

        if not character.is_facing_forward():
            character.action_neutral()


func on_end(state_to, fsm):
    # if state_to == CharStateName.IDLE:
        # character.velocity.x = clamp(character.velocity.x, -character._phys.RUNNING_STOP_SPEED, character._phys.RUNNING_STOP_SPEED)
    # print("stopped running")
    character.emit_signal("stop_walking")
