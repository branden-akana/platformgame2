extends RunnerState
class_name IdleState

func on_update(delta):

    check_dash(runner.DASH_SENSITIVITY)
    check_ground_jump()
    check_dropdown_platforms()
    check_airborne()

    # state behavior

    var axis = input.get_axis()

    var effective_max_walk_speed = runner.WALK_MAX_SPEED * abs(axis.x)

    if is_active():

        if abs(runner.velocity.x) > runner.WALK_MAX_SPEED or axis.x == 0:
            process_friction(delta)
        elif axis.x > runner.WALK_THRESHOLD and is_facing_forward():
            runner.apply_acceleration(delta, 1, runner.ACCELERATION, effective_max_walk_speed)
        elif axis.x < -runner.WALK_THRESHOLD and is_facing_forward():
            runner.apply_acceleration(delta, -1, runner.ACCELERATION, effective_max_walk_speed)
        else:
            update_facing()
