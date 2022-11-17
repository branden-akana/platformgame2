extends CharacterState
class_name SpecialState

# the move that is currently being used
var current_move

# if true, this attack was done checked the ground
var is_grounded: bool = false


func on_start(state_from, character, fsm):
	is_grounded = false

	# check move facing direction
	character.check_facing()

	current_move = character.get_node("moveset/special_heavy")
	current_move.start()

	character.sprite.animation = "attack"
	character.sprite.frame = 0
	
	character.emit_signal("attack")


func on_update(delta, character, fsm):

	if current_move.hit_detected:
		fsm.try_walljump_cancel()  # allow walljump cancelling
		# jump_if_able()  # allow jump canceling

	if not is_current_state(fsm):
		return

	character._friction(delta)

	if character.is_on_floor():
		is_grounded = true
	else:
		fsm.try_fastfall(self)

	# end of move or edge cancelled
	if !current_move.playing or (is_grounded and not character.is_on_floor()):
		fsm.goto_idle_or_dash()

func on_end(state_to, character, fsm):
	current_move.stop()
