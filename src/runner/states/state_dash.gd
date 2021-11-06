extends RunnerState
class_name DashState

export var INIT_DASH_SPEED = 400

export var MAX_DASH_SPEED = 800
export var MAX_DASH_SPEED_REV = 1250

export var DASH_ACCELERATION = 2000 / 0.2
export var DASH_ACCELERATION_REV = 2000 / 0.2

export var DASH_LENGTH = 16  # in frames

func on_start(_old_state):

    # determine dash direction
    update_facing()

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

    check_dash(0.0, true)  # dash-dancing
    check_ground_jump()
    check_dropdown_platforms()
    check_airborne()
    check_idling()

    # =================

    if runner.state_name == "idle":
        print("ended dash at %.3f" % runner.velocity.x)
        runner.velocity.x *= 0.1
    elif not is_active():
        return

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

    # end of dash
    if tick >= DASH_LENGTH and axis.length() > 0.1:
        set_state("running")


    
