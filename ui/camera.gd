extends Node2D
class_name GameCamera

## if true, draw the camera's pos, tracking pos, and boundries
@export var debug_draw: bool = false :
	get:
		return debug_draw
	set(b):
		debug_draw = b
		queue_redraw()

# the path to the target node to follow
@export var target_path: NodePath

@export_group("Camera Behavior")

# length of transition when moving between screens
@export var screen_transition_time = 0.5

# how much to smooth the camera's movements
# (higher = less smooth)
@export var smoothing: float = 1.2;

# the amount of units to snap the camera to.
# this avoids any rendering issues with the pixel shader
@export var pixel_snap: float;

@export var subpixel_fix: bool

# the amount of offset to apply to the camera
@export var offset : Vector2

# camera bounds
# -------------
# these two vectors define an area in which
# the camera is locked inside such that anything
# outside the area will not be visible to the player

# top-left corner of area
var min_position: Vector2 = Vector2.ZERO
# bottom-right corner of area
var max_position: Vector2 = Vector2.ZERO

# tween for focus change transitions
@onready var transition_tween

# tween for the screen shake effect
@onready var shake_tween
var shake_size = 0.0

# the point the camera will be looking at (center of screen)
var focus: Vector2 :
	get:
		return _get_camera_pos()
	set(new_focus):
		focus = new_focus
		_set_camera_pos(new_focus)

# the requested camera position (pre-clamp)
var pre_cam_pos: Vector2

var last_cam_pos: Vector2

var velocity: Vector2 :
	get:
		return focus - last_cam_pos


func init():
	# print("[camera] init")

	# follow the player by default
	track_node(GameState.get_player().get_path())
	await GameState.get_player().respawned

	# try to get the screen the player is checked
	# GameState.set_current_room(get_room_at_target(), false)
	transition_tween.stop()


# get the node that this camera is following
func get_target():
	return get_node_or_null(target_path)

##
## Get the position of the node that this camera is following.
## (adjusting to center the node checked screen)
##
func get_tracking_position() -> Vector2:
	# the camera origin is relative to the top-left corner of the screen,
	# so shift the position by half the screen size to center it
	var pos: Vector2 = get_target().position
	# var pos: Vector2 = get_target().position - (Vector2(Contants.SCREEN_SIZE)() / 2)

	# target position of camera + player offset
	pos = (pos + 
		(get_target().get_facing_dir() * 100) + 
		Vector2(0, -50) +
		(get_target().velocity * 0.25)
	)

	return pos

##
## Set the node for the camera to follow
##
func track_node(nodepath: NodePath) -> void:
	print("[camera] tracking node: %s" % nodepath)
	target_path = nodepath

##
## Set an arbitrary position for the camera to follow
##
func track_pos(_pos: Vector2) -> void:
	pass

##
# Clamp an arbitrary vector to fit within the current bounds.
# Returns the adjusted vector.
##
func clamp_to_bounds(vec: Vector2) -> Vector2:
	if min_position == max_position:
		return vec

	var mn = min_position
	var mx = max_position - Vector2(Constants.SCREEN_SIZE);
	# var x = vec.x
	# var y = vec.y
	# if x > mx.x: x = mx.x
	# if x < mn.x: x = mn.x
	# if y > mx.y: y = mx.y
	# if y < mn.y: y = mn.y
	var x = clampf(vec.x, mn.x, mx.x)
	var y = clampf(vec.y, mn.y, mx.y)
	return Vector2(x, y)

##
# Set the rectangle (world space) that the camera
# will be bound to.
#
# If `do_transition` is true, the game will temporarily pause
# and the camera will smoothly transition to its new bounds.
#
# If `color_palette` is given, the game's color palette
# will also change to the new palette.
##
func set_bounds(tl_pos, br_pos, do_transition = true, color_palette = 0):

	min_position = tl_pos
	max_position = br_pos

	# print("new bounds: %s, %s" % bounds)
	var to = clamp_to_bounds(get_tracking_position())

	if do_transition:
		# print("[camera] moving camera with transition")
		GameState.get_display().change_palette(color_palette)
		await slide_camera_pos(to, screen_transition_time)
	else:
		# print("[camera] moving camera without transition")
		GameState.get_display().change_palette(color_palette, 0.2)
		slide_camera_pos(to)

##
# Return true if the given point is inside the camera viewport.
##
func is_in_view(pos: Vector2) -> bool:
	var cam_pos = focus
	var screen_size = Constants.SCREEN_SIZE
	return (
		cam_pos.x <= pos.x and pos.x <= cam_pos.x + screen_size.x and
		cam_pos.y <= pos.y and pos.y <= cam_pos.y + screen_size.y
	)


func world_to_view(pos: Vector2) -> Vector2:
	return pos - focus


# Smoothly transition the origin of the camera to a specified location.
#
# While this transition is occuring, the game will pause.
# `time` sets how long the transition is (in seconds). If `time` is
# 0, the camera is moved to the new location instantly.
func slide_camera_pos(to, time = 0.0):
	var from = _get_camera_pos()

	if time == 0:
		_set_camera_pos(to)
	else:
		GameState.pause(self)

		if transition_tween:
			transition_tween.kill()

		transition_tween = create_tween()
		transition_tween.tween_method(self._set_camera_pos,
			from, to, time).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)

		await transition_tween.finished
		GameState.unpause(self)

func _get_camera_pos() -> Vector2:
	return -get_viewport().canvas_transform.origin

func _set_camera_pos(new_focus: Vector2):

	var origin

	if pixel_snap:
		# pixel snap camera
		if subpixel_fix:
			origin = (new_focus / pixel_snap).floor() * pixel_snap + Vector2(pixel_snap/2, pixel_snap/2);
		else:
			origin = (new_focus / pixel_snap).floor() * pixel_snap;
	else:
		origin = new_focus

	get_viewport().canvas_transform.origin = -origin
	# target.get_viewport().canvas_transform.origin = -origin


func _process(delta):

	var target = get_node_or_null(target_path)
	
	if (!transition_tween or not transition_tween.is_running()) and target:

		# current position of camera
		var cam_pos = focus

		# determine final tracking position
		var track_pos = get_tracking_position() - (Vector2(Constants.SCREEN_SIZE) / 2.0)

		# smooth movement
		# var new_origin = origin + (pos - origin) * delta * smoothing
		cam_pos = lerp(cam_pos, cam_pos + ((track_pos - cam_pos) * delta), smoothing)
		# var diff = track_pos - cam_pos
		# cam_pos += diff.normalized() * pow(diff.length(), smoothing) * delta

		# clamp camera (not sure why these double negatives are needed)
		pre_cam_pos = cam_pos
		cam_pos = clamp_to_bounds(cam_pos)

		# offset camera (to allow manual panning)
		cam_pos += offset

		# shake camera
		if shake_tween:
			var shake_dir = Vector2(1, 0).rotated(randf_range(0, 2 * PI))
			cam_pos += shake_dir * shake_size

		last_cam_pos = focus
		focus = cam_pos

	if debug_draw: queue_redraw()

func _draw():

	if debug_draw:

		# draw bounds
		if min_position != max_position:
			draw_rect(Rect2(min_position, max_position - min_position), Color.AQUA, false, 4.0)

		# draw tracking position
		draw_circle(get_tracking_position(), 16, Color.BLUE)

		# draw camera position
		draw_circle(focus + (Vector2(Constants.SCREEN_SIZE) / 2), 8, Color.WHITE)

func screen_shake(amount, length):
	if shake_tween:
		shake_tween.kill()
	shake_tween = create_tween()
	shake_size = amount
	shake_tween.tween_property(self, "shake_size", 0, length)

func set_offset(offset_):
	offset = offset_
