#================================================================================
# Character State
#
# Represents a state a character can be in.
#
# on_start(state_from)
# Called when the character enters this state, given the character's previous state.
#
# on_queue_redraw()
# Called every tick while the character is in this state.
#
# on_end()
# Called when the character leaves this state.
#================================================================================
class_name CharacterState extends GenericState

var allowed_actions: Array[int]

var character: Character


func _init(character: Character, allowed_actions: Array[int]):
	self.character = character
	self.allowed_actions = allowed_actions

func _is_allowed(action: int):
	return action in allowed_actions

func _allow(action: int):
	if not (action in allowed_actions):
		allowed_actions.append(action)

func _disallow(action: int):
	if action in allowed_actions:
		allowed_actions.erase(action)