extends RunnerState
class_name JumpsquatState


func on_update(delta, runner, fsm):
    if tick >= runner.JUMPSQUAT_LENGTH:
        # shorthop or fullhop
        var jump_factor = 1.0 if runner.holding_jump() else 0.6
        runner.action_jump(jump_factor)

