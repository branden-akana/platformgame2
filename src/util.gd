extends Node
class_name Util

# Round a vector to the nearest grid position
static func gridsnap(vec: Vector2, grid_size):
    return (vec / grid_size).floor() * grid_size

# Yield using the given object and wait for the "completed" signal
static func await(object):
    return yield(object, "completed")

static func new_tween(parent) -> Tween:
    var tween = Tween.new()
    parent.add_child(tween)
    return tween

# Get the shape of an area's collision, given the Area2D and a shape ID.
static func get_shape(area: Area2D, shape_id: int) -> Shape2D:
    return area.shape_owner_get_shape(area.shape_find_owner(shape_id), shape_id)

# Get a list of collision points between two shapes
static func get_collision_contacts(a: Area2D, a_shape: Shape2D, b: Area2D, b_shape: Shape2D):
    return a_shape.collide_and_get_contacts(
        a.global_transform,
        b_shape,
        b.global_transform
    )
    # var shape = hitbox.shape
    # var contacts = shape.collide_and_get_contacts(
    #     hitbox.global_transform,
    #     Util.get_shape(target, area_shape),
    #     target.global_transform)

static func format_time(time):
    var mins = floor(time / 60.0)
    var secs = floor(fmod(time, 60.0))
    var ms = fmod(time, 1.0) * 1000
    return "%02d:%02d.%03d" % [mins, secs, ms]

static func format_time_diff(time):
    var sig = "+"
    if time < 0:
        sig = "-"
    time = abs(time)
    var mins = floor(time / 60.0)
    var secs = floor(fmod(time, 60.0))
    var ms = fmod(time, 1.0) * 1000
    return "%s%02d:%02d.%03d" % [sig, mins, secs, ms]

# DEBUG DRAWS
# ===============================================================

# Draw a zone for the editor (used for rooms, death zones, etc).
static func draw_zone(node, color, size_offset = 0, inner_box_radius = 16):

    # get the size of the zone from this node's collision
    var collision = node.get_node("collision")
    var extents = collision.shape.extents
    var origin = collision.position - extents

    var offset = Vector2(size_offset, size_offset)

    # var size = extents * 2
    var size = (extents + offset) * 2

    var outer_origin = Vector2.ZERO
    var inner_origin = Vector2(inner_box_radius, inner_box_radius)
    var inner_size = size - (inner_origin * 2)

    node.draw_rect(Rect2(origin + outer_origin - offset, size), color, false, 4.0)
    node.draw_rect(Rect2(origin + inner_origin - offset, inner_size), color, false, 4.0)
