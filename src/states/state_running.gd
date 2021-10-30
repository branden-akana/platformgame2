extends RunnerState
class_name RunningState

export var ACCELERATION = 1000
export var MAX_SPEED = 750

func on_update(delta):

    var axis = buffer.get_action_axis()

    if time == 0:

        # determine running direction
        if runner.velocity.x > 0:
            runner.facing = Direction.RIGHT
        else:
            runner.facing = Direction.LEFT

        runner.emit_signal("walking")

    # jump out of running
    if buffer.is_action_just_pressed("key_jump", 0.2):
        set_state("jumpsquat")

    # dash out of running
    if (
        buffer.is_action_just_pressed("key_right", 0.0, 0.2) or
        buffer.is_action_just_pressed("key_left", 0.0, 0.2)
    ):
        set_state("dash")

    if runner.is_on_floor():

        if axis.x == 0: # no longer moving
            set_state("idle")
        else:
            match runner.facing:
                Direction.RIGHT:
                    if axis.x > 0: # moving right
                        runner.apply_acceleration(delta, axis.x, ACCELERATION, MAX_SPEED)
                    else:
                        set_state("idle")
                Direction.LEFT:
                    if axis.x < 0: # moving left
                        runner.apply_acceleration(delta, axis.x, ACCELERATION, MAX_SPEED)
                    else:
                        set_state("idle")

    else:
        set_state("airborne")

func on_end():
    # print("stopped running")
    runner.emit_signal("stop_walking")
