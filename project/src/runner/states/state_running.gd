extends RunnerState
class_name RunningState

func on_start(old_state):

    # determine running direction
    # update_facing()
    pass

func on_update(delta):

    dash_if_able()
    ground_jump_if_able()
    dropdown_platforms_if_able()
    idle_if_idling()

    if is_active():

        snap_down_to_ground(delta, 16)
        snap_up_to_ground(delta, 16)

        if is_facing_forward():
            process_ground_acceleration(delta)
        else:
            sm.goto_idle()

    goto_airborne_if_not_grounded()

func on_end(state_to):
    if state_to == State.IDLE:
        runner.velocity.x = clamp(runner.velocity.x, -200, 200)
    # print("stopped running")
    runner.emit_signal("stop_walking")
