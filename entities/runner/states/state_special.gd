extends RunnerState
class_name SpecialState

# the move that is currently being used
var current_move

# if true, this attack was done on the ground
var is_grounded: bool = false


func on_start(state_from, runner, fsm):
    is_grounded = false

    # check move facing direction
    runner.check_facing()

    current_move = runner.get_node("moveset/special_heavy")
    current_move.start()

    runner.sprite.animation = "attack"
    runner.sprite.frame = 0
    
    runner.emit_signal("attack")


func on_update(delta, runner, fsm):

    if current_move.hit_detected:
        fsm.try_walljump_cancel()  # allow walljump cancelling
        # jump_if_able()  # allow jump canceling

    if not is_current_state(fsm):
        return

    if runner.is_on_floor():
        is_grounded = true
        process_friction(delta, runner)
    else:
        fsm.try_fastfall(self)
        process_air_acceleration(runner, delta)

    # end of move or edge cancelled
    if !current_move.playing or (is_grounded and not runner.is_on_floor()):
        fsm.goto_idle_or_dash()

func on_end(state_to, runner, fsm):
    current_move.stop()
