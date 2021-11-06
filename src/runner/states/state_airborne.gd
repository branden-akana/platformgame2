extends RunnerState
class_name AirborneState

func on_update(delta):

    check_air_jump()
    check_fastfall()

    if runner.is_on_floor():
        # player landed
        runner.emit_signal("land")
        goto_idle_or_dash()
    else:
        process_gravity(delta)
        process_air_acceleration(delta)
        process_air_friction(delta)
        check_wall_jump()


