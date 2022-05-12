extends RunnerState
class_name AttackState

enum MoveDirection {FORWARD, UP, DOWN}

var moves = {}

# the move that is currently being used
var current_move

# if true, this attack was done on the ground
var b_grounded_attack: bool = false

func get_name(): return "attack_state"

func on_init():
    moves[MoveDirection.FORWARD] = runner.get_node("moveset/normal_forward")
    moves[MoveDirection.UP]      = runner.get_node("moveset/normal_up")
    moves[MoveDirection.DOWN]    = runner.get_node("moveset/normal_down")

func on_start(_state_name):

    runner.b_gravity_enabled = true
    b_grounded_attack = false

    var axis = input.get_axis()

    # check move facing direction
    update_facing()

    # update animation
    runner.sprite.animation = "attack"
    runner.sprite.frame = 0

    # check which move to use
    var attack_direction = MoveDirection.FORWARD
    if round(axis.y) == -1: # aiming up
        attack_direction = MoveDirection.UP
        runner.sprite.animation = "u_attack"
    elif not runner.is_on_floor() and round(axis.y) == 1: # aiming down
        attack_direction = MoveDirection.DOWN
        runner.sprite.animation = "d_attack"

    current_move = moves[attack_direction]
    current_move.start()

    
    runner.emit_signal("attack")

    # runner.camera.screen_shake(16.0, 0.5)

func on_update(delta):

    if current_move.hit_detected:
        walljump_if_able()  # allow walljump canceling
        jump_if_able()  # allow jump canceling

    if not is_active():
        return

    if runner.is_on_floor():
        b_grounded_attack = true
        process_friction(delta)
    else:
        fastfall_if_able()
        process_air_acceleration(delta)

    # end of move or edge cancelled
    if !current_move.playing or (b_grounded_attack and not runner.is_on_floor()):
        sm.goto_idle_or_dash()

func on_end(state_to):
    current_move.stop()
    
