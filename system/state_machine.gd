#================================================================================
# Runner State Machine
#
# A state machine for States. A character will contain one instance of this class.
#
# Contains an instance of every state a character can be in.
# Methods are provided to change the character's state, however,
# the changing of states is managed by each individual state.
#================================================================================

class_name StateMachine extends Resource

signal state_changed

## Dict of state names to state objects.
@export var states: Dictionary = {}

## State name of the current state.
@onready @export var current_state_name: StringName

## The current state.
var current_state: GenericState :
	get:
		return states[current_state_name]

##
## Register a state.
##
func _reg_state(state_name: StringName, state: GenericState) -> GenericState:
	states[state_name] = state
	return state

##
## Get a state from its name.
##
func _get_state(state_name: StringName) -> GenericState:
	return states[state_name] as GenericState


# State Changers
#================================================================================

##
## Return true if the given state name is the current state.
##
func is_current(state_name) -> bool:
	var result = false
	if state_name is StringName:
		result = current_state_name == state_name
	elif state_name is Array:
		result = current_state_name in state_name

	return result

##
## Change the current state. Returns true if the s
##
func change(new_state_name: StringName, force: bool = false) -> bool:
	if not force and new_state_name == current_state_name: return false
	assert(states.has(new_state_name), "Attempted to change to an invalid state.")

	var old_state_name = current_state_name

	# Call on_end() of previous state

	if states.has(current_state_name):
		current_state.on_end(new_state_name, self)

	current_state_name = new_state_name
	current_state = states[current_state_name]
	current_state.reset()

	# Call on_start() of new state

	state_changed.emit(new_state_name, old_state_name)
	current_state.on_start(old_state_name, self)
	# print("changed state: %s -> %s" % [old_state_name, new_state_name])

	return true


func process(delta):

	current_state.update(delta, self)
	on_process(delta, current_state)

func on_process(_delta, _state):
	pass
