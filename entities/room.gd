#===============================================================================
# Node3D
#
# When the player enters this zone, the camera will lock into its dimensions.
# All objects in this room should be its children.
#===============================================================================

@tool
class_name LevelScreen extends Area2D

## Fired when the player enters this screen.
signal screen_entered

## Fired when all enemies on this screen have died.
signal screen_cleared

## The size of this screen (measured in number of screens).
@export var size: Vector2 = Vector2(1, 1) :
	set(new_size):
		size = new_size
		update_size()

@export var palette_idx = 0

@onready var collision: CollisionShape2D = $collision

var enemies: Array[Enemy] = []

var _cleared := false

var is_ready = false

var level = null

func _ready():
	# create a new rectangle shape for the collision
	# this is to ensure individual zones can have different sized shapes
	$collision.shape = RectangleShape2D.new()

	is_ready = true

	update_size()

	connect("body_entered", self.on_body_entered)

	for node in get_tree().get_nodes_in_group("enemy"):
		if is_ancestor_of(node):
			var enemy := node as Enemy
			enemies.append(enemy)
			enemy.enemy_died.connect(on_enemy_death)


func on_enemy_death(_enemy: Enemy) -> void:
	print("room: enemy has died")
	if len(get_alive_enemies()) == 0:
		_cleared = true
		print("ROOM CLEARED!")
		screen_cleared.emit()

func is_cleared() -> bool:
	return _cleared

##
# The size of this screen in pixels.
##
func _real_size() -> Vector2:
	return size * Vector2(Constants.SCREEN_SIZE)

func update_size():
	if ready:
		# offset to account for the size of the player body
		$collision.shape.extents = (_real_size() / 2.0) - Vector2(32, 32)
		$collision.position = _real_size() / 2.0
		queue_redraw()


func get_bounds():
	if is_ready:
		return [position, position + _real_size()]
	else:
		return [position, position + get_viewport().size]

##
# Reset this room.
##
func reset_room():
	for enemy in enemies:
		enemy.reset()

##
# Get a list of enemies in this room that are alive.
##
func get_alive_enemies():
	var enemies = []
	for enemy in self.enemies:
		if enemy.is_alive: enemies.append(enemy)
	
	return enemies


func on_body_entered(body):
	if body is Player:
		emit_signal("screen_entered", self, body)

func _process(_delta):
	if Engine.is_editor_hint(): queue_redraw()

## debug visuals
func _draw():
	if Engine.is_editor_hint():
		var color = Color(1.0, 1.0, 1.0)  # white

		# outline the collision box
		draw_rect(Rect2(0, 0, _real_size().x, _real_size().y), Color.WHITE, false, 2)
		draw_rect(Rect2(8, 8, _real_size().x - 16, _real_size().y - 16), Color.WHITE, false, 2)
		# Util.draw_zone(self, color, 4.0, 32.0)

