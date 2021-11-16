extends RunnerState
class_name JumpsquatState

func on_start(_old_state):
    runner.sprite.animation = "jumpsquat"
    return true

func on_update(delta):

    check_ground_snap_up(delta, 16)

    if tick == runner.JUMPSQUAT_LENGTH:
        if input.is_action_pressed("key_jump"):
            runner.jump()
        else:
            runner.jump(0.7)
