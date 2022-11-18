class_name AttackState extends CharacterState

# the move that is currently being used
var move: Node2D

# if true, this character has landed checked the ground at any point during the attack
var b_grounded_attack: bool


func _init(character, move: Node2D):
	super._init(character, [])
	self.move = move

func on_start(state_from, fsm):
	b_grounded_attack = false

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
	if !move.playing or (b_grounded_attack and not character.is_grounded):
		fsm.goto_any()

func on_end(state_to, fsm):
	_disallow(CharacterActions.AIRDASH)
	_disallow(CharacterActions.JUMP)
	_disallow(CharacterActions.WALLJUMP)
	move.stop()
