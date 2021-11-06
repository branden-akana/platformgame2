extends RunnerState
class_name AttackState

enum MoveDirection {FORWARD, UP, DOWN}

var moves = {}

# the move that is currently being used
var current_move

# if true, this attack was done on the ground
var is_grounded: bool = false

func get_name(): return "attack_state"

func on_init():
    moves[MoveDirection.FORWARD] = runner.get_node("moveset/normal_forward")
    moves[MoveDirection.UP]      = runner.get_node("moveset/normal_up")
    moves[MoveDirection.DOWN]    = runner.get_node("moveset/normal_down")

func on_start(_state_name):

    is_grounded = false

    var axis = input.get_axis()

    # check move facing direction
    update_facing()

    print(axis)

    # check which move to use
    var attack_direction = MoveDirection.FORWARD
    if round(axis.y) == -1: # aiming up
        attack_direction = MoveDirection.UP
    elif not runner.is_on_floor() and round(axis.y) == 1: # aiming down
        attack_direction = MoveDirection.DOWN

    current_move = moves[attack_direction]
    current_move.start()

    runner.sprite.animation = "attack"
    runner.sprite.frame = 0
    
    runner.emit_signal("attack")

    # runner.camera.screen_shake(16.0, 0.5)

func on_update(delta):

    if current_move.hit_detected:
        check_wall_jump()  # allow walljump canceling
        # check_jump()  # allow jump canceling

    if not is_active():
        return

    if runner.is_on_floor():
        is_grounded = true
        process_friction(delta)
    else:
        check_fastfall()
        process_air_acceleration(delta)

    # end of move or edge cancelled
    if !current_move.playing or (is_grounded and not runner.is_on_floor()):
        goto_idle_or_dash()

func on_end():
    current_move.stop()
