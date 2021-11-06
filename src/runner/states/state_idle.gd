extends RunnerState
class_name IdleState

func on_update(delta):

    check_dash(0.3)
    check_ground_jump()
    check_dropdown_platforms()
    check_airborne()

    # state behavior

    var axis = input.get_action_axis()

    if is_active():

        if abs(runner.velocity.x) > runner.WALK_MAX_SPEED * abs(axis.x):
            process_friction(delta)
        else:
            update_facing()
            process_ground_acceleration(delta)