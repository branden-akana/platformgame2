extends RunnerState
class_name RunningState

func on_start(old_state):

    # determine running direction
    update_facing()

func on_update(delta):

    var axis = buffer.get_action_axis()

    check_dash()
    check_ground_jump()
    check_dropdown_platforms()
    check_airborne()
    check_idling()

    if is_active():

        match runner.facing:
            Direction.RIGHT:
                if axis.x > 0: # moving right
                    process_ground_acceleration(delta)
                else:
                    set_state("idle")
            Direction.LEFT:
                if axis.x < 0: # moving left
                    process_ground_acceleration(delta)
                else:
                    set_state("idle")

func on_end():
    # print("stopped running")
    runner.emit_signal("stop_walking")
