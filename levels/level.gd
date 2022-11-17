class_name Level extends Node2D

@export var level_name: String = "untitled"

@export_node_path(RoomZone) var current_room: NodePath

func _ready():
	for room in get_all_rooms():
		room.room_entered.connect(on_room_entered)


func _draw():
	if Engine.is_editor_hint():
		draw_start_point()
		

func _process(_delta):
	if Engine.is_editor_hint():
		queue_redraw()


##
## Get the start point of this level, or (0, 0) if the start point doesn't exist
##
func get_start_point(_idx: int = 0) -> Vector2:
	if $"points/start":
		return $"points/start".global_position
	else:
		return Vector2.ZERO

# Draw a start point indicator at the start point.
func draw_start_point():
	var pt = get_start_point()
	var color = Color(1.0, 1.0, 1.0)
	var points = PackedVector2Array([
		pt + Vector2(0, 16), 
		pt + Vector2(-16, -16),
		pt + Vector2(16, -16),
		pt + Vector2(0, 16),
	])
	draw_polyline(points, color, 4)

##
##
##
func get_enemies() -> Array:
	return []

##
##
##
func get_alive_enemies() -> Array:
	return []

##
## Get the room in focus in the current level.
##
func get_current_room() -> RoomZone:
	return get_node_or_null(current_room) as RoomZone

##
## Get all rooms in the current level.
##
func get_all_rooms() -> Array:
	return get_tree().get_nodes_in_group("room")

##
## Resets all entities in the current room to their initial state.
##
func reset_current_room() -> void:
	var room = get_node_or_null(current_room)
	if room: room.reset_room()

##
## Sets the current room to focus checked.
##
## The camera will now be bound within this room.
## If smooth_transition is true, briefly pause the game and transition
## the camera to the new room. Otherwise, move the camera to the
## new room instantly.
##
func set_current_room(room: RoomZone, do_transition: bool = true):
	# print("entered new room")
	# NOOP if screen is invalid or is already current screen
	if room == null or current_room == room.get_path(): return
	current_room = room.get_path()

	# lock camera to this screen area
	var bounds = room.get_bounds()
	GameState.get_camera().set_bounds(bounds[0], bounds[1], do_transition, room.palette_idx)

##
## Attempt to find a room at this position. If none is found, return null.
##
func get_room_at_point(pos):
	# print("finding %s in %s" % [pos, get_rooms()])
	for room in get_all_rooms():
		# get this room's collision box
		var collision = room.get_node("collision")
		var shape = collision.shape

		# create a rect with the same dimensions as the collision shape
		# then check if a point is inside the rect
		var rect = Rect2(collision.global_position - shape.extents, shape.extents * 2)
		if rect.has_point(pos):
			return room

	return null

##
## Attempt to find a room at a body's position.
## (overlaps_body() doesn't react very well to sudden position changes?)
##
func get_room_at_node(node):
	# use point check function
	return get_room_at_point(node.global_position)

	# if node is PhysicsBody2D:
	#     # use the builtin overlap function
	#     for room in get_rooms():
	#         if room.overlaps_body(node):
	#             return room
	#     return null
	# else:
	#     # use point check function
	#     return get_room_at_point(node.global_position)

##
## Called when a character enters a room.
##
func on_room_entered(room: RoomZone, _player: Character):
	print("entered room: %s" % room.get_name())
	print("    bounds = %s -> %s" % [room.position, room.position + room.size])
	set_current_room(room)
