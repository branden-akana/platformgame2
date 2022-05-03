extends Node2D

const Dust = preload("res://scenes/particles/DustParticles.tscn")
const Jump = preload("res://scenes/particles/JumpParticles.tscn")
const Airdash = preload("res://scenes/particles/airdash_effect.tscn")
const Dash = preload("res://scenes/particles/DashEffect.tscn")
const Land = preload("res://scenes/particles/land_effect.tscn")
const HitEffect = preload("res://scenes/particles/hit_effect.tscn")
const HitParticles = preload("res://scenes/particles/hit_particles.tscn")
const WallJumpLeft = preload("res://scenes/particles/walljump_left.tscn")
const WallJumpRight = preload("res://scenes/particles/walljump_right.tscn")
const Clear = preload("res://scenes/particles/clear_effect.tscn")

func play(scene, parent = get_node("/root/main"), params = {}):
    var effect = scene.instance()
    parent.add_child(effect)

    # don't play any effects from a ghost
    if parent is GhostRunner:
        effect.visible = false

    for key in params:
        effect.set(key, params[key])

    var lifetime = 1.0
    if "lifetime" in effect: lifetime = effect.lifetime

    # call on_particles_finished() at the end of this effect's lifetime
    var timer = get_tree().create_timer(lifetime)
    timer.connect("timeout", self, "on_effect_finished", [effect])

    effect.emitting = true
    return effect

func play_anim(scene, parent = get_node("/root/main")):
    var effect = scene.instance()

    parent.add_child(effect)

    # call on_particles_finished() at the end of this effect's lifetime
    var timer = get_tree().create_timer(5.0)
    timer.connect("timeout", self, "on_effect_finished", [effect])

    effect.play()
    return effect

# called when an effect has finished
func on_effect_finished(node):
    # print("[effects] node %s finished" % node.name)
    if is_instance_valid(node):
        node.queue_free()
