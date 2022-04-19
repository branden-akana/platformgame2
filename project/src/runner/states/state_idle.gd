extends RunnerState
class_name IdleState

func on_update(delta):

    dash_if_able(runner.DASH_SENSITIVITY)
    ground_jump_if_able()
    dropdown_platforms_if_able()

    # state behavior
    if is_active():

        snap_down_to_ground(delta)
        snap_up_to_ground(delta, 16)
    
        var axis = input.get_axis()
        var effective_max_walk_speed = runner.WALK_MAX_SPEED * abs(axis.x)

        if abs(runner.velocity.x) > runner.WALK_MAX_SPEED or axis.x == 0:
            process_friction(delta)
        elif abs(axis.x) == 1 and is_facing_forward():
            sm.goto_dash()
        elif axis.x > runner.WALK_THRESHOLD and is_facing_forward():
            runner.apply_acceleration(delta, 1, runner.ACCELERATION, effective_max_walk_speed)
        elif axis.x < -runner.WALK_THRESHOLD and is_facing_forward():
            runner.apply_acceleration(delta, -1, runner.ACCELERATION, effective_max_walk_speed)
        else:
            update_facing()

    goto_airborne_if_not_grounded()
