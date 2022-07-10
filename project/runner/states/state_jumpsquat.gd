extends RunnerState
class_name JumpsquatState


func on_start(state_from, runner, fsm):
    runner.play_animation("jumpsquat")
    return true


func on_update(delta, runner, fsm):

    #snap_up_to_ground(delta, 16)

    if tick >= runner.JUMPSQUAT_LENGTH:
        # shorthop or fullhop
        if runner.holding_jump():
            runner.jump()
        else:
            runner.jump(0.6)
