extends Node2D
class_name EnemyGroup

onready var enemies = get_children()

onready var game = $"/root/World"

var num_enemies = 0

func _physics_process(_delta):
    num_enemies = 0
    for enemy in enemies:
        if enemy.health > 0:
            num_enemies += 1
            
    if num_enemies == 0 and not game.time_paused:
        game.pause_timer()

func get_num_remaining() -> int:
    var num_enemies = 0
    for enemy in enemies:
        if enemy.health > 0:
            num_enemies += 1
    return num_enemies
    
func reset():
    for enemy in enemies:
        enemy.health = 100
        
