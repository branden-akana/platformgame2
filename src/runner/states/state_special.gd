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
        walljump_if_able()  # allow walljump canceling
        # jump_if_able()  # allow jump canceling

    if not is_active():
        return

    if runner.is_on_floor():
        is_grounded = true
        process_friction(delta)
    else:
        fastfall_if_able()
        process_air_acceleration(delta)

    # end of move or edge cancelled
    if !current_move.playing or (is_grounded and not runner.is_on_floor()):
        sm.goto_idle_or_dash()

func on_end():
    current_move.stop()
