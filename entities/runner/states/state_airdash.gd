extends RunnerState
class_name AirdashState

var airdash_dir: Vector2 = Vector2.ZERO

var particles = null


func can_start(runner) -> bool:
    var axis = runner.get_axis().round().normalized()
    if runner.is_grounded() and axis.is_equal_approx(Vector2.ZERO):
        return false
    return true


func on_start(state_from, runner, fsm):

    # limit to 8 directions
    var axis = runner.get_axis().round().normalized()
    airdash_dir = Vector2.ZERO

    # determine airdash direction
    runner.airdashes_left -= 1
    airdash_dir = Vector2(axis.x, axis.y).normalized();
    #Game.get_camera().screen_shake(1.0, 0.3)

    if runner.is_grounded() and axis.y < 0:
        runner.position.y -= 4

    runner.b_can_slide = false
    runner.emit_signal("airdash")

func on_end(state_to, runner, fsm):

    runner.b_can_slide = true


func on_update(delta, runner, fsm):

    # jump out of dash
    allow_jump_out(runner)
    allow_walljump(runner)

    if not is_current_state(fsm):
        return

    if tick == 1:
        # delayed start of particles
        particles = Effects.play(Effects.Airdash, runner)
        particles.get_node("wave").direction = -airdash_dir
        if runner.facing == Direction.LEFT:
            particles.get_node("trail").material.set_shader_param("flip", true)
        else:
            particles.get_node("trail").material.set_shader_param("flip", false)

    # middle of airdashing
    if tick >= 0 and tick <= runner.AIRDASH_LENGTH:

        # update airdash speed
        var airdash_speed = max(runner.AIRDASH_SPEED, runner.velocity.length())
        var t = pow(tick / float(runner.AIRDASH_LENGTH), 2)
        runner.velocity = (airdash_dir * lerp(
            airdash_speed, runner.AIRDASH_SPEED_END, t
        ))

    # end of airdashing
    if tick > runner.AIRDASH_LENGTH or runner.is_grounded():

        if runner.is_grounded():
            if is_instance_valid(particles):
                particles.emitting = false
            runner.velocity.y = 0
            fsm.goto_idle()
        else:
            fsm.goto_airborne()


    if not is_current_state(fsm) and is_instance_valid(particles):
        particles.emitting = false

    runner.fix_incoming_collisions(delta, 32)