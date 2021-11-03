extends Node
class_name Util

# Round a vector to the nearest grid position
static func gridsnap(vec: Vector2, grid_size):
    return (vec / grid_size).floor() * grid_size

# Yield using the given object and wait for the "completed" signal
static func await(object):
    return yield(object, "completed")

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
static func draw_zone(node, color, inner_box_radius = 16):

    # get the size of the zone from this node's collision
    var collision = node.get_node("collision")
    var extents = collision.shape.extents
    var origin = collision.position - extents
    var size = extents * 2

    var outer_origin = Vector2.ZERO
    var inner_origin = Vector2(inner_box_radius, inner_box_radius)
    var inner_size = size - (inner_origin * 2)

    node.draw_rect(Rect2(origin + outer_origin, size), color, false, 4.0)
    node.draw_rect(Rect2(origin + inner_origin, inner_size), color, false, 4.0)
