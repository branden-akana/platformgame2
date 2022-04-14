extends RunnerState
class_name AirborneState

func on_update(delta):

    air_jump_if_able()
    fastfall_if_able()

    if runner.is_on_floor():
        goto_idle_or_dash()
    else:
        process_gravity(delta)
        process_air_acceleration(delta)
        process_air_friction(delta)
        walljump_if_able()


