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
    
func delete(instance):
    if queued_deletion.find(instance) != -1:
        queued_deletion.append(instance)
        yield(get_tree().create_timer(2.0), "timeout")
        queued_deletion.erase(instance)
        instance.queue_free()

func _physics_process(delta):
    for particles in get_tree().get_nodes_in_group("particles"):
        if particles and not particles.emitting:
            delete(particles)
    
