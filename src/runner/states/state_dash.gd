extends RunnerState
class_name DashState

export var INIT_DASH_SPEED = 800

export var MAX_DASH_SPEED = 800
export var MAX_DASH_SPEED_REV = 1200

export var DASH_ACCELERATION = 1500 / 0.2
export var DASH_ACCELERATION_REV = 2000 / 0.2

export var DASH_LENGTH = 16  # in frames

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

    # transition checks
    # =================

    # dash out of dash (dash dancing)
    if (
        buffer.is_axis_just_pressed("key_right", "key_left", ["key_up", "key_down"], 0.0) or
        buffer.is_axis_just_pressed("key_left", "key_right", ["key_up", "key_down"], 0.0)
    ):
        set_state("dash")

    # jump out of dash
    if buffer.is_action_just_pressed("key_jump", 0.1):
        set_state("jumpsquat")

    # =================

    var axis = buffer.get_action_axis()

    # used to determine which way to accelerate;
    # can only be 1 or -1 (disregard the analog part)
    var effective_axis = 0

    # if true, runner is holding stick in opposite direction
    var is_reversed = false

    match(runner.facing):
        Direction.RIGHT:
            if axis.x >= 0:
                effective_axis = 1
            else:
                is_reversed = true
                effective_axis = -1

        Direction.LEFT:
            if axis.x <= 0:
                effective_axis = -1
            else:
                is_reversed = true
                effective_axis = 1

    var accel = DASH_ACCELERATION
    var max_speed = MAX_DASH_SPEED

    # change acceleration if reversed (allow moonwalking)
    if is_reversed:
        accel = DASH_ACCELERATION_REV
        max_speed = MAX_DASH_SPEED_REV
        
    runner.apply_acceleration(delta, effective_axis, accel, max_speed)

    if axis.length() <= 0.1:  # stick in neutral position
        set_state("idle")

    # airborne check
    if not runner.is_on_floor():
        set_state("airborne")

    # end of dash
    if tick >= DASH_LENGTH and axis.length() > 0.1:
        set_state("running")


    
