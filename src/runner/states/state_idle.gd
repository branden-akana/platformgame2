extends RunnerState
class_name IdleState

export var ACCELERATION = 8000
export var FRICTION = 8000
export var MAX_SPEED = 250

func on_update(delta):
    var axis = buffer.get_action_axis()

    if (
        buffer.is_axis_just_pressed("key_right", "key_left", [], 0.0, 0.3) or
        buffer.is_axis_just_pressed("key_left", "key_right", [], 0.0, 0.3)
    ):
        set_state("dash")

    # state behavior

    if runner.is_on_floor():

        if abs(runner.velocity.x) > MAX_SPEED * abs(axis.x):
            runner.apply_friction(delta)
        else:
            if axis.x > 0:
                runner.facing = Direction.RIGHT
            elif axis.x < 0:
                runner.facing = Direction.LEFT

            runner.apply_acceleration(delta, axis.x, ACCELERATION, MAX_SPEED)

        if buffer.is_action_just_pressed("key_down"):
            runner.position += Vector2(0, 1)
    else:
        set_state("airborne")

    if buffer.is_action_just_pressed("key_jump", 0.2):
        set_state("jumpsquat")
