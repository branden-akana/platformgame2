class_name AttackState extends CharacterState

# the move that is currently being used
var move: Node2D

# if true, this character has landed checked the ground at any point during the attack
var b_grounded_attack: bool


func _init(character, move: Node2D, allowed_actions: Array[int]):
	super._init(character, allowed_actions)
	self.move = move
                   
func on_start(_state_from, _fsm):
	if not character.is_grounded:
		_allow(CharacterActions.LAND)
	else:
		_disallow(CharacterActions.LAND)

func on_update(delta, fsm):

	if tick == 0:
		move.start()

	move.move_update(delta)

	if move.hit_detected:
		_allow(CharacterActions.AIRDASH)
		_allow(CharacterActions.JUMP)
		_allow(CharacterActions.WALLJUMP)

	if not is_current(fsm): return

	if character.is_grounded:
		character._friction(delta)
		b_grounded_attack = true
	else:
		character._acceleration(delta)

	# end of move or edge cancelled
	if !move.playing:
		fsm.goto_any()

func on_end(_state_to, _fsm):
	_disallow(CharacterActions.AIRDASH)
	_disallow(CharacterActions.JUMP)
	_disallow(CharacterActions.WALLJUMP)
	_disallow(CharacterActions.LAND)
	move.stop()
