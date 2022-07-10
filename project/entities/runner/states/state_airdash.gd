extends RunnerState
class_name AirdashState

var airdash_dir: Vector2 = Vector2.ZERO
var on_ground: bool = false

var particles = null


func on_start(state_from, runner, fsm):

    # limit to 8 directions
    var axis = runner.get_axis().round().normalized()
    airdash_dir = Vector2.ZERO

    # determine airdash direction
    on_ground = (
        state_from is IdleState
        or state_from is DashState
        or state_from is RunningState
        or state_from is AttackState
    )

    runner.airdashes_left -= 1
    airdash_dir = Vector2(axis.x, axis.y).normalized();
    #Game.get_camera().screen_shake(1.0, 0.3)

    runner.emit_signal("airdash")


func on_update(delta, runner, fsm):

    # jump out of dash
    allow_jump_out(runner)
    allow_walljump(runner)

    if not is_current_state(fsm):
        return

    if not runner.is_on_floor():
        on_ground = false

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

        runner.align_to_platform(delta)

    # end of airdashing
    if tick > runner.AIRDASH_LENGTH or (not on_ground and runner.is_on_floor()):

        if runner.is_grounded():
            if is_instance_valid(particles):
                particles.emitting = false
            fsm.goto_idle()
        else:
            fsm.goto_airborne()

    if not is_current_state(fsm) and is_instance_valid(particles):
        particles.emitting = false
