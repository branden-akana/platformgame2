extends Node2D

const Dust = preload("res://scenes/particles/DustParticles.tscn")
const Jump = preload("res://scenes/particles/JumpParticles.tscn")
const Airdash = preload("res://scenes/particles/AirdashEffect.tscn")
const Dash = preload("res://scenes/particles/DashEffect.tscn")
const Land = preload("res://scenes/particles/land_effect.tscn")
const HitEffect = preload("res://scenes/particles/hit_effect.tscn")
const HitParticles = preload("res://scenes/particles/hit_particles.tscn")
const WallJumpLeft = preload("res://scenes/particles/walljump_left.tscn")
const WallJumpRight = preload("res://scenes/particles/walljump_right.tscn")
const Clear = preload("res://scenes/particles/clear_effect.tscn")

var queued_deletion = []

func play(scene, parent = get_node("/root/main"), params = {}):
    var instance = scene.instance()
    for key in params:
        instance.set(key, params[key])

    parent.add_child(instance)
    instance.add_to_group("particles")
    instance.restart()

    if parent is GhostPlayer:
        instance.visible = false

    return instance

func play_anim(scene, parent = get_node("/root/main")):
    var instance = scene.instance()

    parent.add_child(instance)
    instance.play()

    if parent is GhostPlayer:
        instance.visible = false

    return instance
    
func delete(particles):
    if not particles in queued_deletion:
        queued_deletion.append(particles)
        yield(get_tree().create_timer(1.0), "timeout")
        if is_instance_valid(particles):
            particles.free()
        queued_deletion.erase(particles)
        

func _physics_process(delta):
    for particles in get_tree().get_nodes_in_group("particles"):
        if particles and not particles.emitting:
            call_deferred("delete", particles)
    
