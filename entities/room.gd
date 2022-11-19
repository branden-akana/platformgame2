#===============================================================================
# Node3D
#
# When the player enters this zone, the camera will lock into its dimensions.
# All objects in this room should be its children.
#===============================================================================

class_name RoomZone extends Area2D

signal room_entered

@export var size: Vector2 = Vector2(1920, 1080) :
	set(new_size):
		size = new_size
		set_size(new_size)

@export var palette_idx = 0

@onready var collision: CollisionShape2D = $collision

var is_ready = false

func _ready():
	# create a new rectangle shape for the collision
	# this is to ensure individual zones can have different sized shapes
	$collision.shape = RectangleShape2D.new()

	is_ready = true

	# set_size(size)

	connect("body_entered", self.on_body_entered)
	connect("room_entered", GameState.on_room_entered)


func set_size(size):
	if ready:
		# offset to account for the size of the player body
		$collision.shape.extents = (size / 2.0) - Vector2(32, 32)
		$collision.position = size / 2.0
		queue_redraw()


func get_bounds():
	if ready:
		return [position, position + size]
	else:
		return [position, position + get_viewport().size]

# Reset this room.
func reset_room():
	for enemy in get_enemies():
		enemy.reset()

# Get a list of enemies in this room.
func get_enemies():
	var enemies = []
	for child in get_children():
		if "enemy" in child.get_groups():
			enemies.append(child)
		
		# also get enemies in doors
		if "door" in child.get_groups():
			for c in child.get_children():
				if "enemy" in c.get_groups():
					enemies.append(c)

	return enemies

# Get a list of enemies in this room that are alive.
func get_alive_enemies():
	var enemies = []
	for enemy in get_enemies():
		if enemy.health > 0:
			enemies.append(enemy)
	
	return enemies

func on_body_entered(body):
	if body is PlayerCharacter:
		emit_signal("room_entered", self, body)

# debug visuals
func _draw():
	if Engine.is_editor_hint():
		var color = Color(1.0, 1.0, 1.0)  # white

		# outline the collision box
		Util.draw_zone(self, color, 4.0, 32.0)

