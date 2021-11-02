extends Node2D

const Dust = preload("res://scenes/particles/DustParticles.tscn")
const Jump = preload("res://scenes/particles/JumpParticles.tscn")
const Airdash = preload("res://scenes/particles/AirdashEffect.tscn")
const Dash = preload("res://scenes/particles/DashEffect.tscn")

var queued_deletion = []

func play(scene, parent, params = {}):
    var instance = scene.instance()
    for key in params:
        instance.set(key, params[key])

    parent.add_child(instance)
    instance.add_to_group("particles")
    instance.restart()

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
    
