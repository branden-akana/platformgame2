@tool
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

		if not emitting and mod_value: start()
		emitting = mod_value

func _ready():
	for child in get_children():
		if child is CPUParticles2D or child is GPUParticles2D:
			child.emitting = false
			child.one_shot = true
	finished.connect(_on_finished)

func _is_particle_type(node) -> bool:
	return node is CPUParticles2D or node is GPUParticles2D or node is ParticleGroup

func _on_finished() -> void:
	emitting = false

##
## Return the actual lifetime (time until last particle dies).
## The longest lifetime of all child particle nodes will be returned.
##
func _get_lifetime() -> float:
	var lifetime := 0.0
	for particles in get_children():
		var p_lifetime = 0.0

		if particles is CPUParticles2D or particles is GPUParticles2D:
			p_lifetime = particles.lifetime * (2 - particles.explosiveness) / particles.speed_scale
		elif particles is ParticleGroup:
			p_lifetime = particles._get_lifetime()

		if p_lifetime > lifetime: lifetime = p_lifetime

	return lifetime

##
## Start emitting the particle group.
## If emit is true, emit the finished signal after the group's lifetime.
##
func start(emit := true) -> void:
	for particles in get_children():
		if particles is CPUParticles2D or particles is GPUParticles2D:
			particles.restart()
		if particles is ParticleGroup:
			particles.start(false)

	if emit:
		get_tree().create_timer(_get_lifetime()).timeout.connect(Callable(emit_signal).bind("finished"))
