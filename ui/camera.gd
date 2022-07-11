extends Node2D
class_name GameCamera

# length of transition when moving between screens
export var screen_transition_time = 0.5

# how much to smooth the camera's movements
# (higher = less smooth)
export var smoothing: float = 1.2;

# the amount of units to snap the camera to.
# this avoids any rendering issues with the pixel shader
export var pixel_snap: float = 4.0;

# the amount of offset to apply to the camera
export (Vector2) var offset = Vector2(0.0, 0.0);

# the path to the target node to follow
export (NodePath) var target_path;

# camera bounds
# -------------
# these two vectors define an area in which
# the camera is locked inside such that anything
# outside the area will not be visible to the player

# top-left corner of area
var min_position = Vector2(0, 0)
# bottom-right corner of area
var max_position = Vector2(1280, 720)

# tween for focus change transitions
var transition_tween = Tween.new()

# tween for the screen shake effect
var shake_tween = Tween.new()
var shake_size = 0.0

# the point the camera will be looking at (center of screen)
var focus = Vector2.ZERO setget set_camera_focus, get_camera_focus

func _ready():
    add_child(transition_tween)
    add_child(shake_tween)

    set_camera_focus(clamp_origin())
    # real_origin = get_camera_focus()

func init():
    # print("[camera] init")

    # follow the player by default
    set_target(Game.get_player().get_path())
    yield(Game.get_player(), "respawned")

    # try to get the screen the player is on
    Game.set_current_room(get_room_at_target(), false)
    transition_tween.reset_all()


# get the size of the window as a vector
func get_window_size() -> Vector2:
    return get_viewport().size
    # return OS.window_size


# get the node that this camera is following
func get_target():
    return get_node_or_null(target_path)


# get the position of the node that this camera is following
# (adjusting to center the node on screen)
func get_target_camera_pos() -> Vector2:
    # the camera origin is relative to the top-left corner of the screen,
    # so shift the position by half the screen size to center it
    return get_target().position - (get_window_size() / 2)


# set the node for the camera to follow
func set_target(nodepath):
    print("[camera] setting target to %s" % nodepath)
    target_path = nodepath


# Clamp the camera focus to fit within the current bounds.
# Returns the adjusted focus.
func clamp_focus(vec):
    var mn = min_position
    var mx = max_position - get_window_size()
    return Vector2(clamp(vec.x, mn.x, mx.x), clamp(vec.y, mn.y, mx.y))


# Return true if the camera focus is inside the current bounds.
func is_in_bounds(vec, mn, mx):
    return (mn.x >= vec.x and vec.x >= mx.x) and (mn.y >= vec.y and vec.y >= mx.y)


# Set the rectangle (world space) that the camera
# will be bound to.
#
# If `do_transition` is true, the game will temporarily pause
# and the camera will smoothly transition to its new bounds.
#
# If `color_palette` is given, the game's color palette
# will also change to the new palette.
func set_bounds(tl_pos, br_pos, do_transition = true, color_palette = 0):

    min_position = tl_pos
    max_position = br_pos

    # print("new bounds: %s, %s" % bounds)
    var to = clamp_focus(get_target_camera_pos())

    if do_transition:
        # print("[camera] moving camera with transition")
        var tween_2 = Game.get_display_manager().change_palette(color_palette)
        var tween_1 = move_focus(to, screen_transition_time)
        yield(tween_1, "completed")
        yield(tween_2, "completed")
    else:
        # print("[camera] moving camera without transition")
        Game.get_display_manager().change_palette(color_palette, 0.2)
        move_focus(to)
        yield(get_tree(), "idle_frame")


# Smoothly transition the origin of the camera to a specified location.
#
# While this transition is occuring, the game will pause.
# `time` sets how long the transition is (in seconds). If `time` is
# 0, the camera is moved to the new location instantly.
func move_focus(to, time = 0.0):
    var from = get_camera_focus()

    if time == 0:
        set_camera_focus(to)
    else:
        Game.pause(self)
        transition_tween.interpolate_method(
            self, "set_camera_focus", from, to, time,
            Tween.TRANS_QUART, Tween.EASE_OUT)
        transition_tween.start()
        yield(transition_tween, "tween_completed")
        Game.unpause(self)

func get_camera_focus():
    var target = get_node_or_null(target_path)
    if target:
        return -target.get_viewport().canvas_transform.origin
    else:
        return Vector2.ZERO

func set_camera_focus(new_focus):

    var target = get_node_or_null(target_path)
    if target:

        focus = new_focus

        # pixel snap camera
        var origin = (new_focus / pixel_snap).floor() * pixel_snap + Vector2(pixel_snap/2, pixel_snap/2);
        target.get_viewport().canvas_transform.origin = -origin


func _process(delta):
    
    var target = get_node(target_path)
    
    if not transition_tween.is_active() and target:
        # current position of camera
        var origin = focus

        # target position of camera
        var pos = get_target_camera_pos() + (get_target().get_facing_dir() * 200)

        # smooth movement
        # var new_origin = origin + (pos - origin) * delta * smoothing
        var diff = pos - origin
        origin += diff.normalized() * pow(diff.length(), smoothing) * delta

        # clamp camera (not sure why these double negatives are needed)
        origin = clamp_focus(origin)

        # offset camera (to allow manual panning)
        origin += offset

        # shake camera
        if shake_tween.is_active():
            var shake_dir = Vector2(1, 0).rotated(rand_range(0, 2 * PI))
            origin += shake_dir * shake_size

        set_camera_focus(origin)

# Get the room at the current target (if any).
func get_room_at_target():
    return Game.get_room_at_point(get_target().global_position)

func clamp_origin():
    return clamp_focus(get_camera_focus())

func screen_shake(amount, length):
    shake_tween.interpolate_property(self, "shake_size", amount, 0, length)
    shake_tween.start()

func set_offset(offset_):
    offset = offset_
