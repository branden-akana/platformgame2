extends RunnerState
class_name DashState

export var DASH_SPEED = 500

func on_update(delta):

    var axis = buffer.get_action_axis()

    # dash dancing
    if (
        buffer.is_action_just_pressed("key_right") or
        buffer.is_action_just_pressed("key_left")
    ):
        set_state("dash")

    # jump out of dash
    if buffer.is_action_just_pressed("key_jump", 0.1):
        set_state("jumpsquat")

    if time == 0: # start of dash

        # determine dash direction
        if axis.x > 0:
            runner.facing = Direction.RIGHT
        elif axis.x < 0:
            runner.facing = Direction.LEFT

        # play dash sound
        runner.play_sound("walk", -20, 0.8, true)

        # set velocity
        match runner.facing:
            Direction.RIGHT:
                runner.play_particle_effect(runner.DashEffect, {"direction": Vector2(-3, -1)})
                runner.velocity.x = DASH_SPEED
            Direction.LEFT:
                runner.play_particle_effect(runner.DashEffect, {"direction": Vector2(3, -1)})
                runner.velocity.x = -DASH_SPEED

    if 0 <= time and time <= 0.2: # middle of dashing
        runner.apply_acceleration(delta, axis.x, 2000, 750)

    if 0.2 <= time: # end of dash
        set_state("running")

    if not runner.is_on_floor():
        set_state("airborne")

    