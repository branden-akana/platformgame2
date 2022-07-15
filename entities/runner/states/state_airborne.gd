extends RunnerState
class_name AirborneState

func on_start(state_from, runner, fsm):
    runner.set_grounded(false)
    runner.airborne_height = runner.position.y
    runner.b_gravity_enabled = true


func on_update(delta, runner, fsm):

    allow_jump_out(runner)
    allow_fastfall(runner)
    allow_walljump(runner)
    allow_land_out(runner)

    process_air_acceleration(runner, delta)
    process_air_friction(runner, delta)

    if runner.position.y < runner.airborne_height:
        runner.airborne_height = runner.position.y
