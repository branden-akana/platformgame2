extends RunnerState
class_name JumpsquatState

export var JUMPSQUAT_FRAMES = 4

func on_start(_old_state):
    runner.sprite.animation = "jumpsquat"

func on_update(_delta):

    if tick >= JUMPSQUAT_FRAMES:
        runner.jump()
        set_state("airborne")
