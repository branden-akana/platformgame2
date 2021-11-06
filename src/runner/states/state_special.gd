extends RunnerState
class_name SpecialState

# the move that is currently being used
var current_move

# if true, this attack was done on the ground
var is_grounded: bool = false

func on_init():
    current_move = runner.get_node("moveset/special_heavy")

func on_start(_state_name):
    is_grounded = false

    # check move facing direction
    update_facing()

    current_move.start()

    runner.sprite.animation = "attack"
    runner.sprite.frame = 0
    
    runner.emit_signal("attack")

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
        reset_state()

func on_end():
    current_move.stop()
