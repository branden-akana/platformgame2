extends Node2D

const Dust = preload("res://effects/particles/DustParticles.tscn")
const Jump = preload("res://effects/particles/JumpParticles.tscn")
const Airdash = preload("res://effects/particles/airdash_effect.tscn")
const Dash = preload("res://effects/particles/DashEffect.tscn")
const Land = preload("res://effects/particles/land_effect.tscn")
const HitEffect = preload("res://effects/particles/hit_effect.tscn")
const HitParticles = preload("res://effects/particles/hit_particles.tscn")
const WallJumpLeft = preload("res://effects/particles/walljump_left.tscn")
const WallJumpRight = preload("res://effects/particles/walljump_right.tscn")
const Clear = preload("res://effects/particles/clear_effect.tscn")

func play(scene, parent = get_node("/root/main"), params = {}):
	var effect = scene.instantiate()
	parent.add_child(effect)

	# don't play any effects from a ghost
	# if parent is GhostCharacter:
		# effect.visible = false

	for key in params:
		effect.set(key, params[key])

	var lifetime = 1.0
	if "lifetime" in effect: lifetime = effect.lifetime

	# call on_particles_finished() at the end of this effect's lifetime
	var timer = get_tree().create_timer(lifetime)
	timer.connect("timeout",Callable(self,"on_effect_finished").bind(effect))

	effect.emitting = true
	return effect

func play_anim(scene, parent = get_node("/root/main")):
	var effect = scene.instantiate()

	parent.add_child(effect)

	# call on_particles_finished() at the end of this effect's lifetime
	var timer = get_tree().create_timer(5.0)
	timer.connect("timeout",Callable(self,"on_effect_finished").bind(effect))

	effect.play()
	return effect

# called when an effect has finished
func on_effect_finished(node):
	# print("[effects] node %s finished" % node.name)
	if is_instance_valid(node):
		node.queue_free()
