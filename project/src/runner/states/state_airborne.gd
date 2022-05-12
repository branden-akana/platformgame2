extends RunnerState
class_name AirborneState

func on_start(state_from):
    runner.b_is_grounded = false
    runner.b_gravity_enabled = true

func on_update(delta):

    air_jump_if_able()
    fastfall_if_able()

    if runner.is_on_floor():
        sm.goto_idle_or_dash()
    else:
        process_air_acceleration(delta)
        process_air_friction(delta)
        walljump_if_able()


