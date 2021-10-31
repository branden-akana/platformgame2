extends RunnerState
class_name AirdashState

export var DODGE_SPEED = 1000
export var DODGE_LENGTH = 0.2

var airdash_dir: Vector2 = Vector2.ZERO
var grounded: bool = false

var particles = null

func can_start():

    var axis = buffer.get_action_axis()
    return round(axis.length()) != 0

func on_start(state_name):

    var axis = buffer.get_action_axis().round().normalized();
    airdash_dir = Vector2.ZERO

    # determine airdash direction
    if runner.airdashes_left == 0 or axis == Vector2.ZERO:
        set_state("airborne")
        return
    else:
        grounded = state_name in ["idle", "dash", "running"]

        runner.airdashes_left -= 1
        airdash_dir = Vector2(axis.x, axis.y).normalized();
        #Game.get_camera().screen_shake(1.0, 0.3)

        # if runner.is_on_floor():
        #     runner.position.y -= 2


func on_update(_delta):

    if tick == 1:
        # delayed start of particles
        particles = Effects.play(Effects.Airdash, runner)
        if runner.facing == Direction.LEFT:
            particles.material.set_shader_param("flip", true)
        else:
            particles.material.set_shader_param("flip", false)

    # jump out of dash
    if buffer.is_action_just_pressed("key_jump", 0.2):
        runner.jump()
        set_state("airborne")
        return

    if time >= 0 and time < DODGE_LENGTH:

        # middle of airdashing

        var airdash_speed = max(DODGE_SPEED, runner.velocity.length())
        runner.velocity = airdash_dir * lerp(airdash_speed, airdash_speed / 2, pow(time / DODGE_LENGTH, 2))

    if time >= DODGE_LENGTH or (not grounded and runner.is_on_floor()):

        # end of airdashing

        if runner.is_on_floor():
            if particles:
                particles.emitting = false
            runner.emit_signal("land")
            set_state("idle")
        else:
            set_state("airborne")
