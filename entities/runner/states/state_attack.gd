extends RunnerState
class_name AttackState

# the move that is currently being used
var move: Node2D

# if true, this runner has landed on the ground at any point during the attack
var b_grounded_attack: bool


func _init(move: Node2D):
    self.move = move

func on_start(state_from, runner, fsm):
    b_grounded_attack = false

func on_update(delta, runner, fsm):

    if tick == 0:
        move.start()

    move.move_update(delta)

    if move.hit_detected:
        allow_airdash_cancel()
        allow_jump_cancel()
        allow_walljump_cancel()

    if not is_current_state(fsm): return

    if runner.is_grounded():
        b_grounded_attack = true
        process_friction(runner, delta)
    else:
        fsm.try_fastfall(self)
        process_air_acceleration(runner, delta)

    # end of move or edge cancelled
    if !move.playing or (b_grounded_attack and not runner.is_grounded()):
        fsm.goto_any()

func on_end(state_to, runner, fsm):
    b_can_airdash_cancel = false
    b_can_jump_cancel = false
    b_can_walljump_cancel = false
    move.stop()
    
