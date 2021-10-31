extends RunnerState
class_name DashState

export var INIT_DASH_SPEED = 100
export var MAX_DASH_SPEED = 800
export var DASH_ACCELERATION = 1000 / 0.2

func on_start(_old_state):

    var axis = buffer.get_action_axis()

    # determine dash direction
    if axis.x > 0:
        runner.facing = Direction.RIGHT
    elif axis.x < 0:
        runner.facing = Direction.LEFT

    # play dash sound
    runner.emit_signal("dash")

    # set velocity
    match runner.facing:
        Direction.RIGHT:
            Effects.play(Effects.Dash, runner, {"direction": Vector2(-3, -1)})
            runner.velocity.x = INIT_DASH_SPEED
        Direction.LEFT:
            Effects.play(Effects.Dash, runner, {"direction": Vector2(3, -1)})
            runner.velocity.x = -INIT_DASH_SPEED

func on_update(delta):

    var axis = buffer.get_action_axis()

    # dash out of dash (dash dancing)
    if (
        buffer.is_action_just_pressed("key_right", 0, 0.6) or
        buffer.is_action_just_pressed("key_left", 0, 0.6)
    ):
        set_state("dash")

    # jump out of dash
    if buffer.is_action_just_pressed("key_jump", 0.1):
        set_state("jumpsquat")

    var accel = DASH_ACCELERATION
    var max_speed = MAX_DASH_SPEED

    # increase acceleration in reverse (allow moonwalking)
    if (
        (runner.facing == Direction.RIGHT and axis.x < 0) or
        (runner.facing == Direction.LEFT and axis.x > 0)
    ):
        accel *= 2
        max_speed *= 1.5
        
    runner.apply_acceleration(delta, axis.x, accel, max_speed)

    if round(axis.length()) == 0:  # neutral position
        set_state("idle")

    # ground check
    if not runner.is_on_floor():
        set_state("airborne")

    if tick >= 20: # end of dash
        set_state("running")


    
