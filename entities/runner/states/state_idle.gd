extends RunnerState
class_name IdleState

func on_update(delta, runner, fsm):

    allow_dash_out(runner)
    allow_jump_out(runner)
    allow_dropdown(runner)
    allow_air_out(runner)

    runner.apply_friction(delta)

    var x = runner.get_axis_x()
    if abs(runner.velocity.x) < runner.WALK_MAX_SPEED and abs(round(x)) == 1:
        fsm.goto_dash()

    # walk implementation

    # var effective_max_walk_speed = runner.WALK_MAX_SPEED * abs(x)

    # if abs(runner.velocity.x) > runner.WALK_MAX_SPEED or x == 0:
    #     runner.apply_friction(delta)
    # elif x > runner.WALK_THRESHOLD and runner.is_facing_forward():
    #     runner.apply_acceleration(delta, 1, runner.ACCELERATION, effective_max_walk_speed)
    # elif x < -runner.WALK_THRESHOLD and runner.is_facing_forward():
    #     runner.apply_acceleration(delta, -1, runner.ACCELERATION, effective_max_walk_speed)
    # elif abs(x) == 1:
    #     fsm.goto_dash()
    # else:
    #     runner.set_facing_to_input()
