#================================================================================
# Character State Machine
#
# A state machine for CharacterStates. A character will contain one instance of this class.
#
# Contains an instance of every state a character can be in.
# Methods are provided to change the character's state, however,
# the changing of states is managed by each individual state.
#================================================================================

class_name CharStateMachine extends StateMachine

var b_was_grounded: bool = false

## The character this state machine belongs to.
var character

## Initialize the state machine and all the states.
func _init(character):

	print("init char state machine")
	self.character = character

	current_state_name = CharStateName.IDLE

	_reg_state(CharStateName.IDLE, IdleState.new(character, [
		CharacterActions.AIRDASH,
		CharacterActions.ATTACK,
		CharacterActions.SPECIAL,
		CharacterActions.JUMP,
		CharacterActions.DASH,
		# CharacterActions.EDGE_CANCEL,
		CharacterActions.AIR_CANCEL,
		# CharacterActions.IDLE_CANCEL,
		CharacterActions.DROPDOWN,
		# CharacterActions.FASTFALL,
		# CharacterActions.LAND,
		# CharacterActions.WALLJUMP,
	]))

	_reg_state(CharStateName.DASH, DashState.new(character))

	_reg_state(CharStateName.RUNNING, RunningState.new(character, [
		CharacterActions.AIRDASH,
		CharacterActions.ATTACK,
		CharacterActions.SPECIAL,
		CharacterActions.JUMP,
		CharacterActions.DASH,
		CharacterActions.EDGE_CANCEL,
		CharacterActions.AIR_CANCEL,
		CharacterActions.IDLE_CANCEL,
		CharacterActions.DROPDOWN,
		# CharacterActions.FASTFALL,
		# CharacterActions.LAND,
		# CharacterActions.WALLJUMP,
	]))

	_reg_state(CharStateName.AIRBORNE, AirborneState.new(character, [
		CharacterActions.AIRDASH,
		CharacterActions.ATTACK,
		CharacterActions.SPECIAL,
		CharacterActions.JUMP,
		# CharacterActions.DASH,
		# CharacterActions.EDGE_CANCEL,
		# CharacterActions.AIR_CANCEL,
		# CharacterActions.IDLE_CANCEL,
		# CharacterActions.DROPDOWN,
		CharacterActions.FASTFALL,
		CharacterActions.LAND,
		CharacterActions.WALLJUMP,
	]))

	_reg_state(CharStateName.AIRDASH, AirdashState.new(character, [
		CharacterActions.AIRDASH,
		CharacterActions.ATTACK,
		CharacterActions.SPECIAL,
		CharacterActions.JUMP,
		# CharacterActions.DASH,
		# CharacterActions.EDGE_CANCEL,
		# CharacterActions.AIR_CANCEL,
		# CharacterActions.IDLE_CANCEL,
		# CharacterActions.DROPDOWN,
		CharacterActions.FASTFALL,
		# CharacterActions.LAND,
		CharacterActions.WALLJUMP,
	]))

	_reg_state(CharStateName.JUMPSQUAT, JumpsquatState.new(character, [
		CharacterActions.AIRDASH,
		# CharacterActions.ATTACK,
		# CharacterActions.SPECIAL,
		# CharacterActions.DASH,
		# CharacterActions.EDGE_CANCEL,
		# CharacterActions.AIR_CANCEL,
		# CharacterActions.IDLE_CANCEL,
		# CharacterActions.DROPDOWN,
		# CharacterActions.FASTFALL,
		# CharacterActions.LAND,
		# CharacterActions.WALLJUMP,
	]))

	_reg_state(CharStateName.ATTACK, AttackState.new(character, []))

	print("initialized char state machine")





# State Changers
#================================================================================

func on_process(_delta, state: CharacterState):

	if state.tick == 0: return

	# print("state_process: %s" % character.tick)
	# print("%s: %s" % [current_state_name, state.allowed_actions])

	# THE BELOW CHECKS WILL APPLY TO ALL STATES
	#------------------------------------------

	# goto airborne if not grounded and was previously grounded.
	# if character.is_grounded:
	# 	b_was_grounded = true

	# Check if the player wants to dash.
	if state._is_allowed(CharacterActions.DASH):
		# and (character.pressed_left() or character.pressed_right())):
		# if (character.input.pressed_left_thru_neutral() or 
		# character.input.pressed_right_thru_neutral()):
		if character.input.pressed_left():
			character.action_dash(Direction.LEFT)

		elif character.input.pressed_right():
			character.action_dash(Direction.RIGHT)

	# allow airdash
	if state._is_allowed(CharacterActions.AIRDASH):
		if character.input.pressed_airdash():
			character.action_airdash()

	# if state._is_allowed(CharacterActions.EDGE_CANCEL):
	# 	if b_was_grounded and not character.is_grounded:
	# 		character.action_airborne()

	if state._is_allowed(CharacterActions.AIR_CANCEL):
		if not character.is_grounded:
			character.action_airborne()

	# Switch player to any grounded state if grounded.
	if state._is_allowed(CharacterActions.LAND):
		if character.is_grounded:
			goto_grounded()

	# Check if the player wants to drop-down a platform.
	if state._is_allowed(CharacterActions.DROPDOWN):
		if character.input.pressed_down():
			character.action_dropdown()

	# Check if the player wants to do a walljump.
	if state._is_allowed(CharacterActions.WALLJUMP):
		character.action_walljump()

	# Check if the player wants to do a jump (air or grounded).
	if state._is_allowed(CharacterActions.JUMP):
		if character.input.pressed_jump():
			character.action_jump()
			return

	# Check if the player wants to fastfall.
	if state._is_allowed(CharacterActions.FASTFALL):
		if character.input.pressed_down():
			character.action_fastfall()

	# Check if player is trying to not move (no movement input)
	if state._is_allowed(CharacterActions.IDLE_CANCEL):
		if (
			character.input.is_axis_neutral() and
			character.is_grounded
			# and not character.input.holding_left()
			# and not character.input.holding_right()
		):
			character.action_neutral()

	# allow attack
	if state._is_allowed(CharacterActions.ATTACK):
		if character.input.pressed_attack():
			character.action_attack()

	# allow special attack
	if state._is_allowed(CharacterActions.SPECIAL):
		if character.input.pressed_special():
			character.action_special()

##
# Set the character state to either idle, running or dash
# depending checked the current state of the character.
##
func goto_grounded() -> void:
	# melee-like behavior
	#goto_idle()

	# more forgiving behavior
	if character.is_facing_forward():
		character.action_run()
	else:
		character.action_neutral()

##
# Set the character state to either idle, running, dash, or airborne
# depending checked the current state of the character.
##
func goto_any():
	if character.is_grounded:
		goto_grounded()
	else:
		character.action_airborne()

# State Transition Setters
#===============================================================================
