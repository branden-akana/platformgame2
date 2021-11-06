extends RunnerState
class_name JumpsquatState

func on_start(_old_state):
    runner.sprite.animation = "jumpsquat"
    return true

func on_update(_delta):

    if tick == runner.JUMPSQUAT_LENGTH:
        if input.is_action_pressed("key_jump"):
            runner.jump()
        else:
            runner.jump(0.7)
        set_state("airborne")
