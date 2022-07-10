extends RunnerState
class_name AttackState


# the move that is currently being used
var move

# if true, this runner has landed on the ground at any point during the attack
var b_grounded_attack: bool

func get_name(): return "attack_state"


func on_start(state_from, runner, fsm):
    b_grounded_attack = false


func on_update(delta, runner, fsm):

    if tick == 0:
        move.start()

    move.move_update(delta)

    if move.hit_detected:
        allow_walljump(runner)  # allow walljump canceling
        allow_jump_out(runner)  # allow jump canceling

    if not is_current_state(fsm): return

    if runner.is_grounded():
        b_grounded_attack = true
        process_friction(runner, delta)
    else:
        allow_fastfall(runner)
        process_air_acceleration(runner, delta)

    # end of move or edge cancelled
    if !move.playing or (b_grounded_attack and not runner.is_grounded()):
        fsm.goto_any()

func on_end(state_to, runner, fsm):
    move.stop()
    
