class_name TimedParticles extends CPUParticles2D

signal finished


##
# Get accurate particle lifetime (time until last particle dies).
##
func _get_lifetime() -> float:
	return lifetime * (2 - explosiveness)

func start() -> void:
	if not emitting:
		emitting = true
		get_tree().create_timer(_get_lifetime()).timeout.connect(Callable(emit_signal).bind("finished"))