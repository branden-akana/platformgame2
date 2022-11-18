class_name Enemy extends CharacterBody2D

## Fired when this enemy's HP hits 0.
signal enemy_died


@export var max_health: int = 1 :
	get:
		return max_health # TODOConverter40 Non existent get function 
	set(max_hp):
		max_health = max_hp
		reset()

@onready @export var health = max_health

# the original position of this enemy
@onready var home: Vector2 = position

# flags

var is_alive = true

var is_visible_when_dead = false

func _ready():
	print("enemy position: %s" % position)
	reset()
	
func reset():
	health = max_health
	is_alive = true

	if home:
		position = home
		print("set enemy position: %s" % home)

func hurt(_from, dmg = 1):
	health = max(0, health - dmg)
		
	if health == 0 and is_alive:
		is_alive = false
		enemy_died.emit(self)


# func on_area_enter(area):
#     var no_damage = area.get_parent().no_damage
#     if not no_damage:
#         hit_shift = Vector2.ZERO
#         hit_direction = area.get_parent().position.direction_to(position)
#         hit_elasticity = HIT_ELASTICITY
#         color_blend = HIT_COLOR_LENGTH
#         health = 0

