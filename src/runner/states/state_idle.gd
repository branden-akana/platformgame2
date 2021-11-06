extends RunnerState
class_name IdleState

export var ACCELERATION = 8000
export var FRICTION = 8000
export var MAX_SPEED = 250

func on_update(delta):

    check_dash(0.3)
    check_ground_jump()
    check_dropdown_platforms()
    check_airborne()

    # state behavior

    var axis = input.get_action_axis()

    if is_active():

        if abs(runner.velocity.x) > MAX_SPEED * abs(axis.x):
            process_friction(delta)
        else:
            update_facing()
            process_ground_acceleration(delta)