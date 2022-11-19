#================================================================================
# Character State Machine
#
# A state machine for CharacterStates. A character will contain one instance of this class.
#
# Contains an instance of every state a character can be in.
# Methods are provided to change the character's state, however,
# the changing of states is managed by each individual state.
#================================================================================

class_name StateMachine

signal state_changed

var states = {}

var character

# if not null, contains the next state to transition to
# during the current physics tick.
var queued_state_type = null

var current_type: StringName = CharStateName.IDLE

var b_was_grounded: bool = false

func is_in_state(state_type) -> bool:
	if state_type is int:
		return current_type == state_type
	elif state_type is Array:
		return current_type in state_type
	else:
		return false

func _set_state(state_type: StringName, state: CharacterState):
	states[state_type] = state

func _state(state_type: StringName) -> CharacterState:
	return states[state_type] as CharacterState

func _current_state() -> CharacterState:
	return states[current_type] as CharacterState

# Initialize the state machine and all the states.
func init(character):
	print("init char state machine")
	self.character = character

	_set_state(CharStateName.IDLE, IdleState.new())
	_set_state(CharStateName.DASH, DashState.new())
	_set_state(CharStateName.RUNNING, RunningState.new())
	_set_state(CharStateName.AIRBORNE, AirborneState.new())
	_set_state(CharStateName.AIRDASH, AirdashState.new())
	_set_state(CharStateName.JUMPSQUAT, JumpsquatState.new())

	_set_state(CharStateName.ATT_FORWARD,
		AttackState.new(character.get_node("moveset/normal_forward")))
	_set_state(CharStateName.ATT_UAIR,
		AttackState.new(character.get_node("moveset/normal_up")))
	_set_state(CharStateName.ATT_DAIR,
		AttackState.new(character.get_node("moveset/normal_down")))

	_set_state(CharStateName.SPECIAL, SpecialState.new())

	var state = _state(CharStateName.IDLE)
	state.allow_dropdown()
	state.allow_dash_cancel()
	state.allow_jump_cancel()
	state.allow_air_cancel()
	state.allow_airdash_cancel()
	state.allow_attack_cancel()
	state.allow_special_cancel()

	state = _state(CharStateName.DASH)
	state.allow_dropdown()
	state.allow_dash_cancel()
	state.allow_jump_cancel()
	state.allow_edge_cancel()
	state.allow_idle_cancel()
	state.allow_airdash_cancel()
	state.allow_attack_cancel()
	state.allow_special_cancel()

	state = _state(CharStateName.RUNNING)
	state.allow_dropdown()
	state.allow_dash_cancel()
	state.allow_jump_cancel()
	state.allow_edge_cancel()
	state.allow_idle_cancel()
	state.allow_airdash_cancel()
	state.allow_attack_cancel()
	state.allow_special_cancel()

	state = _state(CharStateName.AIRBORNE)
	state.allow_jump_cancel()
	state.allow_walljump_cancel()
	state.allow_land_cancel()
	state.allow_fastfall()
	state.allow_airdash_cancel()
	state.allow_attack_cancel()
	state.allow_special_cancel()

	state = _state(CharStateName.AIRDASH)
	state.allow_jump_cancel()
	state.allow_walljump_cancel()
	# state.allow_land_cancel()
	state.allow_airdash_cancel()
	state.allow_attack_cancel()
	state.allow_special_cancel()

	state = _state(CharStateName.JUMPSQUAT)
	state.allow_airdash_cancel()
	state.allow_attack_cancel()
	state.allow_special_cancel()





# State Changers
#================================================================================

# Queue a state to transition to.
func queue_state(state_type: StringName) -> void:
	# print("queued state: %s" % CharStateName.get_name(state_type))
	# queued_state_type = state_type
	set_state(state_type)

# Set the state of the handle
func set_state(new_state_name):
	# if state_type == current_type: return
	if character and new_state_name in states:

		var old_state_name = current_type
		var new_state = states[new_state_name]

		if new_state.can_start(character):
			# Call on_end() of previous state

			var current_state = _current_state()

			if current_type:
				current_state.on_end(new_state_name, character, character.fsm)

			current_type = new_state_name
			current_state = states[current_type]
			current_state.time = 0.0
			current_state.tick = 0
			b_was_grounded = false

			# Call on_start() of new state

			emit_signal("state_changed", new_state_name, old_state_name)
			current_state.on_start(old_state_name, character, character.fsm)

func process(delta):
	if character == null: return

	var state = _current_state()

	# THE BELOW CHECKS WILL APPLY TO ALL STATES
	#------------------------------------------

	# goto airborne if not grounded and was previously grounded.
	if character.is_grounded():
		b_was_grounded = true

	if state.b_can_edge_cancel and b_was_grounded and not character.is_grounded():
		character.fsm.goto_airborne()

	if state.b_can_air_cancel and not character.is_grounded():
		character.fsm.goto_airborne()

	# Switch player to any grounded state if grounded.
	try_land_cancel(state)
	
	# allow airdash
	try_airdash_cancel(state)

	# Check if the player wants to drop-down a platform.
	if state.b_can_dropdown and character.pressed_down():
		character.action_dropdown()

	# Check if the player wants to do a walljump.
	try_walljump_cancel(state)

	# Check if the player wants to do a jump (air or grounded).
	try_jump_cancel(state)

	# Check if the player wants to fastfall.
	try_fastfall(state)

	# Check if the player wants to dash.
	if (state.b_can_dash_cancel
		# and (character.pressed_left() or character.pressed_right())):
		and (character.pressed_left_thru_neutral() or character.pressed_right_thru_neutral())):
		character.action_dash()

	# Check if player is trying to not move (no movement input)
	if state.b_can_idle_cancel and character.is_axis_neutral():
		character.action_neutral()

	# allow attack
	if state.b_can_attack_cancel and character.pressed_attack():
		character.action_attack()

	# allow special attack
	if state.b_can_special_cancel and character.pressed_special():
		character.action_special()

	state = _current_state()

	# transition to queued state if any
	if queued_state_type != null:
		set_state(queued_state_type)
		queued_state_type = null

	# update current state
	var next_state = state.on_update(delta, character, self)
	if next_state != null:
		# print("next state: %s" % next_state)
		set_state(next_state)

	state.tick += 1
	state.time += delta

func try_airdash_cancel(state):
	if state.b_can_airdash_cancel and character.pressed_airdash():
		character.action_airdash()

func try_land_cancel(state):
	if state.b_can_land_cancel and character.is_grounded():
		goto_grounded()
		return true
	return false

func try_fastfall(state):
	if state.b_can_fastfall and character.pressed_down():
		character.action_fastfall()
		return true
	return false

func try_jump_cancel(state):
	if state.b_can_jump_cancel and character.pressed_jump():
		character.action_jump()
		return true
	return false

func try_walljump_cancel(state) -> bool:
	if state.b_can_walljump_cancel:
		return character.action_walljump()
	return false

func goto_idle():      queue_state(CharStateName.IDLE)
func goto_running():   queue_state(CharStateName.RUNNING)
func goto_dash():      queue_state(CharStateName.DASH)

func goto_jumpsquat(): queue_state(CharStateName.JUMPSQUAT)
func goto_airborne():  queue_state(CharStateName.AIRBORNE)

func goto_airdash():   queue_state(CharStateName.AIRDASH)

func goto_attack():    queue_state(CharStateName.ATTACK)
func goto_special():   queue_state(CharStateName.SPECIAL)
		
# Set the character state to either idle, running or dash
# depending checked the current state of the character.
func goto_grounded() -> void:
	# melee-like behavior
	#goto_idle()

	# more forgiving behavior
	if character.is_facing_forward():
		goto_running()
	else:
		goto_idle()

# Set the character state to either idle, running, dash, or airborne
# depending checked the current state of the character.
func goto_any():
	if character.is_grounded():
		goto_grounded()
	else:
		goto_airborne()

# State Transition Setters
#===============================================================================
