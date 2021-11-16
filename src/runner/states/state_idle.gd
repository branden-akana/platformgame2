extends RunnerState
class_name IdleState

func on_update(delta):

    check_dash(runner.DASH_SENSITIVITY)
    check_ground_jump()
    check_dropdown_platforms()

    # state behavior
    if is_active():

        check_ground_snap_down(delta)
        check_ground_snap_up(delta, 16)
    
        var axis = input.get_axis()
        var effective_max_walk_speed = runner.WALK_MAX_SPEED * abs(axis.x)

        if abs(runner.velocity.x) > runner.WALK_MAX_SPEED or axis.x == 0:
            process_friction(delta)
        elif abs(axis.x) == 1 and is_facing_forward():
            set_state("dash")
        elif axis.x > runner.WALK_THRESHOLD and is_facing_forward():
            runner.apply_acceleration(delta, 1, runner.ACCELERATION, effective_max_walk_speed)
        elif axis.x < -runner.WALK_THRESHOLD and is_facing_forward():
            runner.apply_acceleration(delta, -1, runner.ACCELERATION, effective_max_walk_speed)
        else:
            update_facing()

    check_airborne()
