extends RunnerState
class_name AirborneState

export var AIR_ACCELERATION = 2000
export var AIR_MAX_SPEED = 600
export var FAST_FALL_SPEED = 2500

func on_update(delta):

    var axis = buffer.get_action_axis()

    if runner.is_on_floor():
        # player landed
        runner.emit_signal("land")
        reset_state()
    else:
        runner.apply_gravity(delta)

        # air acceleration
        runner.apply_acceleration(delta, axis.x, AIR_ACCELERATION, AIR_MAX_SPEED)

    if buffer.is_action_just_pressed("key_down") and runner.velocity.y > 0:
        runner.velocity.y = FAST_FALL_SPEED

    if buffer.is_action_just_pressed("key_jump", 0.2):
        runner.jump()
