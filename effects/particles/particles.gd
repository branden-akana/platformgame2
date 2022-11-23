extends Node2D

const Dust = preload("res://effects/particles/fx_drag.tscn")
const Jump = preload("res://effects/particles/fx_jump.tscn")
const Airdash = preload("res://effects/particles/fx_airdash.tscn")
const Dash = preload("res://effects/particles/fx_dash.tscn")
const Land = preload("res://effects/particles/fx_land.tscn")
const HitEffect = preload("res://effects/particles/fx_hit.tscn")
const HitParticles = preload("res://effects/particles/hit_particles.tscn")
const WallJumpLeft = preload("res://effects/particles/fx_wjump_l.tscn")
const WallJumpRight = preload("res://effects/particles/fx_wjump_r.tscn")
const Clear = preload("res://effects/particles/clear_effect.tscn")

func play(scene, parent = get_node("/root/main"), params = {}):
	var effect = scene.instantiate()
	parent.add_child(effect)

	for key in params:
		effect.set(key, params[key])
		
	if effect.has_method("start"):
		effect.start()
		effect.connect("finished", on_effect_finished.bind(effect))

	return effect

func play_anim(scene, parent = get_node("/root/main/viewport")):
	var effect = scene.instantiate()

	parent.add_child(effect)

	# call on_particles_finished() at the end of this effect's lifetime
	var timer = get_tree().create_timer(5.0)
	timer.connect("timeout",Callable(self,"on_effect_finished").bind(effect))

	effect.play()
	return effect

# called when an effect has finished
func on_effect_finished(node):
	# print("effect finished: %s" % node.name)
	if is_instance_valid(node):
		node.queue_free()
