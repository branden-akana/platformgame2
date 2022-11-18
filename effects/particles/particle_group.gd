class_name ParticleGroup extends Node2D

signal finished


@export @onready var emitting: bool = false :
	get:
		# var is_emitting = false

		# for child in get_children():
		# 	if child is CPUParticles2D:
		# 		if (child as CPUParticles2D).emitting:
		# 			is_emitting = true

		# return is_emitting
		return emitting

	set(mod_value):

		for child in get_children():
			if child is CPUParticles2D:
				child.emitting = mod_value

		emitting = mod_value

func restart():
	for child in get_children():
		if child is CPUParticles2D:
			(child as CPUParticles2D).restart()

func _get_lifetime() -> float:
	var lifetime := 0.0
	for particles in get_children():
		if particles is CPUParticles2D:
			var p_lifetime = particles._get_lifetime()
			if p_lifetime > lifetime: lifetime = p_lifetime

	return lifetime

func start() -> void:
	for particles in get_children():
		if particles is CPUParticles2D: particles.start()
		get_tree().create_timer(_get_lifetime()).timeout.connect(Callable(emit_signal).bind("finished"))
