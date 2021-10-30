extends Node2D
class_name GameCamera

export var smoothing: float = 10;
export var snapping: float = 4.0;
export (Vector2) var offset = Vector2(0.0, 0.0);
export (NodePath) var target_path;

export var region_transition_time = 5.0;

# top-left corner of region
var min_position = Vector2(0, 0)
# bottom-right corner of region
var max_position = Vector2(1280, 720)
var region_transition = 0.0
var transition_tween = Tween.new()

var real_origin = Vector2.ZERO
var current_zone = null
var monitoring_zones = false
var initial_zone_set = false

var shake_max_time = 0.0
var shake_time = 0.0
var shake_size = 0.0

func _ready():
    add_child(transition_tween)

    set_camera_origin(clamp_origin())

    real_origin = get_camera_origin()

func init():
    print("initializing camera")
    target_path = Game.get_player().get_path()
    current_zone = null
    initial_zone_set = false
    monitoring_zones = true
    detect_zones()

func get_target():
    return get_node(target_path)

func get_target_camera_pos() -> Vector2:
    # the camera origin is relative to the top-left corner of the screen,
    # so shift the position by half the screen size to center it
    return get_target().position - (OS.window_size/2)

func set_target(nodepath):
    target_path = nodepath
    detect_zones()

func clamp_vec(vec):
    var mn = min_position
    var mx = max_position - OS.window_size
    return Vector2(clamp(vec.x, mn.x, mx.x), clamp(vec.y, mn.y, mx.y))

func is_in_region(vec, mn, mx):
    return (mn.x >= vec.x and vec.x >= mx.x) and (mn.y >= vec.y and vec.y >= mx.y)

func set_zone(zone, smooth_transition = true):
    current_zone = zone

    min_position = zone.position
    max_position = zone.position + (zone.region_size * 64)
    
    var to = clamp_vec(get_target_camera_pos())

    if smooth_transition:
        var tween_2 = HUD.change_palette(zone.palette_idx)
        var tween_1 = tween_origin(to, 0.5)
        yield(tween_1, "completed")
        yield(tween_2, "completed")
    else:
        HUD.change_palette(zone.palette_idx, 0.2)
        tween_origin(to, 0.0)
        yield(get_tree(), "idle_frame")


func tween_origin(to, time = 0.5):
    
    var from = real_origin

    if time == 0:
        set_camera_origin(to)
        yield(get_tree(), "idle_frame")
    else:
        Game.pause(self)
        transition_tween.interpolate_method(
            self, "set_camera_origin", from, to, time,
            Tween.TRANS_QUART, Tween.EASE_OUT)
        transition_tween.start()
        yield(transition_tween, "tween_completed")
        Game.unpause(self)

func get_camera_origin():
    var target = get_node(target_path)
    if target:
        return -target.get_viewport().canvas_transform.origin
    else:
        return Vector2.ZERO

func set_camera_origin(vec):

    var target = get_node(target_path)
    if target:

        real_origin = vec

        # pixel snap camera
        var origin = (vec / snapping).floor() * snapping + Vector2(snapping/2, snapping/2);
    
        target.get_viewport().canvas_transform.origin = -origin
        # need to also set the origins of each viewport manually
        Game.get_foreground().canvas_transform.origin = -origin
        Game.get_fg2().canvas_transform.origin = -origin

func _process(delta):
    
    var target = get_node(target_path)
    
    if not transition_tween.is_active() and target:
        var origin = real_origin
        var pos = get_target_camera_pos()

        # smooth movement
        # var new_origin = origin + (pos - origin) * delta * smoothing
        origin += (pos - origin) * delta * smoothing

        # clamp camera (not sure why these double negatives are needed)
        origin = clamp_vec(origin)

        # offset camera
        origin += offset

        # shake camera
        if shake_time > 0:
            var shift = Vector2(1, 0).rotated(rand_range(0, 2 * PI))
            origin += shift * lerp(0.0, shake_size, shake_time / shake_max_time)
            shake_time -= delta

        set_camera_origin(origin)

func get_all_zones() -> Array:
    return get_tree().get_nodes_in_group("camera_zone")

# Gets the camera zone at this node.
# (doesn't react very well to sudden position changes?)
func get_zone_at_node(node):
    for zone in get_all_zones():
        if zone.overlaps_body(node):
            return zone
    return null

# Gets the camera zone at this position.
func get_zone_at_point(pos):
    for zone in get_all_zones():
        var collision = zone.get_node("collision")
        var shape = collision.shape
        var rect = Rect2(collision.global_position - shape.extents, shape.extents * 2)
        if rect.has_point(pos):
            return zone
    return null

func detect_zones():
    var zone = get_zone_at_point(get_target().position)
    # print(zone)
    if zone and zone != current_zone:
        if not initial_zone_set:
            print("setting initial zone: %s" % zone)
            yield(set_zone(zone, false), "completed")
            initial_zone_set = true
        else:
            print("setting zone: %s" % zone)
            set_zone(zone)

func _physics_process(delta):
    if monitoring_zones:
        detect_zones()

    # var intersects = get_world_2d().direct_space_state.intersect_point(
    #     get_target().global_position, 32, [], 0b100000,
    #     true, true)
    # print("intersects: %s" % [intersects])

func clamp_origin():
    return clamp_vec(get_camera_origin())

func screen_shake(amount, length):

    shake_max_time = length
    shake_time = length
    shake_size = amount

func set_offset(offset_):
    offset = offset_
