extends RunnerState
class_name DashState

func on_start(_old_state):

    # determine dash direction
    update_facing()

    # play dash sound
    runner.emit_signal("dash")

    # set velocity
    match runner.facing:
        Direction.RIGHT:
            Effects.play(Effects.Dash, runner, {"direction": Vector2(-3, -1)})
            runner.velocity.x = runner.DASH_INIT_SPEED
        Direction.LEFT:
            Effects.play(Effects.Dash, runner, {"direction": Vector2(3, -1)})
            runner.velocity.x = -runner.DASH_INIT_SPEED

func on_update(delta):

    # transition checks
    # =================

    dash_if_able(0.0, true)  # dash-dancing
    ground_jump_if_able()
    dropdown_platforms_if_able()
    idle_if_idling()

    # =================

    if sm.current_state is IdleState:
        runner.velocity.x = runner.DASH_STOP_SPEED

    if is_active():

        snap_down_to_ground(delta)
        snap_up_to_ground(delta, 16)

        var axis = input.get_axis()

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

        var accel = runner.DASH_ACCELERATION
        var max_speed = runner.DASH_MAX_SPEED

        # change acceleration if reversed (allow moonwalking)
        if is_reversed:
            accel = runner.DASH_ACCELERATION_REV
            max_speed = runner.DASH_MAX_SPEED_REV
            
        runner.apply_acceleration(delta, effective_axis, accel, max_speed)

        # end of dash
        if tick >= runner.DASH_LENGTH and axis.length() > 0.1:
            sm.goto_idle_or_run()

    goto_airborne_if_not_grounded()


    
