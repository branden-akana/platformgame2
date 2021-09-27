extends Node2D
class_name GameCamera



export var smoothing: float = 50;
export var snapping: float = 4.0;
export (Vector2) var offset = Vector2(0.0, 0.0);
export (NodePath) var target_path;

export var region_transition_time = 5.0;

onready var game = $"/root/World"

# top-left corner of region
var min_position = Vector2(0, 0)
# bottom-right corner of region
var max_position = Vector2(1280, 720)
var region_transition = 0.0
var transition_tween = Tween.new()

var shake_max_time = 0.0
var shake_time = 0.0
var shake_size = 0.0

func _ready():
    add_child(transition_tween)
    
func get_target():
    return get_node(target_path)

func clamp_vec(vec):
    var mn = min_position
    var mx = max_position - OS.window_size
    return Vector2(clamp(vec.x, mn.x, mx.x), clamp(vec.y, mn.y, mx.y))

func is_in_region(vec, mn, mx):
    return (mn.x >= vec.x and vec.x >= mx.x) and (mn.y >= vec.y and vec.y >= mx.y)

func set_region(min_pos, max_pos):

    min_position = min_pos
    max_position = max_pos

    var from = get_camera_origin()
    var to = clamp_vec(get_target().position - Vector2(1280 / 2, 720 / 2))

    transition_tween.interpolate_method(
        self, "set_camera_origin", from, to, 0.5,
        Tween.TRANS_QUART, Tween.EASE_OUT)
    transition_tween.start()
    game.game_paused = true
    yield(transition_tween, "tween_completed")
    game.game_paused = false

func get_camera_origin():
    var target = get_node(target_path)
    if target:
        return -target.get_viewport().canvas_transform.origin
    else:
        return Vector2.ZERO

func set_camera_origin(vec):

    var target = get_node(target_path)
    if target:
        # pixel snap camera
        vec = (vec / snapping).floor() * snapping + Vector2(snapping/2, snapping/2);

        target.get_viewport().canvas_transform.origin = -vec

func _process(delta):
    
    var target = get_node(target_path)
    
    if not transition_tween.is_active() and target:
        var origin = get_camera_origin()
        var pos = target.position - OS.window_size/2

        if shake_time > 0:
            var shift = Vector2(1, 0).rotated(deg2rad(rand_range(0, 360)))
            origin += shift * lerp(0.0, shake_size, shake_time / shake_max_time)
            shake_time -= delta

        # lerp from current position to position of target
        var new_origin = lerp(origin, pos, clamp(10 * delta, 0, 1))

        # clamp camera (not sure why these double negatives are needed)
        var clamped_origin = clamp_vec(new_origin)

        # smooth transition when setting region bounds
        if region_transition > 0.0:
            new_origin = lerp(clamped_origin, origin, ease(region_transition / region_transition_time, 5))
            region_transition = max(region_transition - delta, 0.0)
        else:
            new_origin = clamped_origin

        set_camera_origin(new_origin)

func clamp_origin():
    return clamp_vec(get_camera_origin())

func screen_shake(amount, length):

    shake_max_time = length
    shake_time = length
    shake_size = amount
