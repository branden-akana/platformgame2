extends RunnerState
class_name RunningState

func on_start(old_state):

    # determine running direction
    # update_facing()
    pass

func on_update(delta):

    check_dash()
    check_ground_jump()
    check_dropdown_platforms()
    check_idling()

    if is_active():

        check_ground_snap_down(delta, 16)
        check_ground_snap_up(delta, 16)

        if is_facing_forward():
            process_ground_acceleration(delta)
        else:
            set_state("idle")

    check_airborne()

func on_end():
    # print("stopped running")
    runner.emit_signal("stop_walking")
