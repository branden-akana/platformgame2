class_name AttackState extends CharacterState

var moves = []

# true if the player has started this attack on the floor
var b_grounded_attack: bool


func on_start(_state_from, _fsm, args):
    moves = args

    # update facing direction
    character.set_facing_to_input()

    b_grounded_attack = false

    character.moveset.play_move(moves[0])


func on_update(delta, fsm):

    if character.input.pressed_attack() and len(moves) > 1:
        character._attack(moves.slice(1))
        return

    if character.moveset.hit_detected:
        _allow(CharacterActions.AIRDASH)
        _allow(CharacterActions.JUMP)
        _allow(CharacterActions.WALLJUMP)

    if not character.is_grounded:
        character._acceleration(delta)
    else:
        b_grounded_attack = true

    character._friction(delta)

    if not character.moveset.is_playing() or b_grounded_attack and not character.is_grounded:
        fsm.goto_any()


func on_end(_state_to, _fsm):
    _disallow(CharacterActions.AIRDASH)
    _disallow(CharacterActions.JUMP)
    _disallow(CharacterActions.WALLJUMP)
    _disallow(CharacterActions.LAND)

    character.moveset.stop_move()

