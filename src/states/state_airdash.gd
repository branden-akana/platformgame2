extends RunnerState
class_name AirdashState

export var DODGE_SPEED = 1000
export var DODGE_LENGTH = 0.2

var airdash_dir: Vector2 = Vector2.ZERO
var grounded: bool = false

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
        if runner.camera:
            runner.camera.screen_shake(8.0, 0.3)

        # if runner.is_on_floor():
        #     runner.position.y -= 2


func on_update(_delta):

    # jump out of dash
    if buffer.is_action_just_pressed("key_jump", 0.2):
        runner.jump()
        set_state("airborne")
        return

    if time >= 0 and time < DODGE_LENGTH:

        # middle of airdashing

        var airdash_speed = max(DODGE_SPEED, runner.velocity.length())
        if runner.facing == Direction.LEFT:
            runner.airdash_effect.material.set_shader_param("flip", true)
        else:
            runner.airdash_effect.material.set_shader_param("flip", false)
        runner.airdash_effect.emitting = true
        runner.velocity = airdash_dir * lerp(airdash_speed, airdash_speed / 2, pow(time / DODGE_LENGTH, 2))

    if time >= DODGE_LENGTH or (not grounded and runner.is_on_floor()):

        # end of airdashing

        runner.airdash_effect.emitting = false
        if runner.is_on_floor():
            runner.play_sound("land", -20)
        reset_state()
