
class_name GenericState extends Resource

var time: float = 0.0  # the amount of time (in seconds) the character has been in this state
var tick: int = 0      # the amount of time (in ticks) the character has been in this state

##
## Reset this state.
##
func reset():
	self.time = 0.0
	self.tick = 0

##
## Update this state.
##
func update(delta: float, fsm):
	self.on_update(delta, fsm)
	self.time += delta
	self.tick += 1

##
## Returns true if this state is active.
##
func is_current(fsm) -> bool:
	return fsm.current_state == self

##
## called at the beginning of the state
##
func on_start(_state_from, _fsm, _args) -> void:
	pass

##
## Called every physics process.
##
## If this function returns a RunnerStateType, this state is considered
## finished and the player should transition to that state.
##
func on_update(_delta: float, _fsm):
	return null

##
## called at the end of the state.
##
func on_end(_state_to, _fsm) -> void:
	pass
