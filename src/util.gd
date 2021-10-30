extends Node
class_name Util

# Round a vector to the nearest grid position
static func gridsnap(vec: Vector2, grid_size):
    return (vec / grid_size).floor() * grid_size

# Yield using the given object and wait for the "completed" signal
static func await(object):
    return yield(object, "completed")
