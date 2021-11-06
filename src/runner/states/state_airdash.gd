extends RunnerState
class_name AirdashState

var airdash_dir: Vector2 = Vector2.ZERO
var grounded: bool = false

var particles = null

func can_start():

    var axis = input.get_action_axis()
    return round(axis.length()) != 0

func on_start(state_name):

    var axis = input.get_action_axis().round().normalized();
    airdash_dir = Vector2.ZERO

    # determine airdash direction
    if runner.airdashes_left == 0 or axis == Vector2.ZERO:
        set_state("airborne")
        return
    else:
        grounded = state_name in ["idle", "dash", "running", "attack"]

        runner.airdashes_left -= 1
        airdash_dir = Vector2(axis.x, axis.y).normalized();
        #Game.get_camera().screen_shake(1.0, 0.3)

        # if runner.is_on_floor():
        #     runner.position.y -= 2

    runner.emit_signal("airdash")


func on_update(_delta):

    # jump out of dash
    check_air_jump(true)
    check_wall_jump()

    if not is_active():
        return

    if tick == 1:
        # delayed start of particles
        particles = Effects.play(Effects.Airdash, runner)
        particles.get_node("wave").direction = -airdash_dir
        if runner.facing == Direction.LEFT:
            particles.get_node("trail").material.set_shader_param("flip", true)
        else:
            particles.get_node("trail").material.set_shader_param("flip", false)

    if tick >= 0 and tick <= runner.AIRDASH_LENGTH:

        # middle of airdashing

        var airdash_speed = max(runner.AIRDASH_SPEED, runner.velocity.length())
        var t = pow(tick / float(runner.AIRDASH_LENGTH), 2)
        runner.velocity = (airdash_dir * lerp(
            airdash_speed, runner.AIRDASH_SPEED_END, t
        ))

    if tick > runner.AIRDASH_LENGTH or (not grounded and runner.is_on_floor()):

        # end of airdashing

        if runner.is_on_floor():
            if is_instance_valid(particles):
                particles.emitting = false
            runner.emit_signal("land")
            # set_state("idle")
            reset_state()
        else:
            set_state("airborne")
