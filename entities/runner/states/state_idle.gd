extends RunnerState
class_name IdleState

func on_update(delta, runner, fsm):

    runner.apply_friction(delta)

    var x = runner.get_axis_x()
    if abs(runner.velocity.x) < runner.WALK_MAX_SPEED and abs(round(x)) == 1:
        return RunnerStateType.DASH