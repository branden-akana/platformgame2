#===============================================================================
# Room
#
# When the player enters this zone, the camera will lock into its dimensions.
# All objects in this room should be its children.
#===============================================================================

extends Area2D
class_name Room
tool

signal room_entered

export (Vector2) var size = Vector2(20, 11.25) setget set_size
export var palette_idx = 0

onready var collision: CollisionShape2D = $collision

var ready = false

func _ready():
    # create a new rectangle shape for the collision
    # this is to ensure individual zones can have different sized shapes
    $collision.shape = RectangleShape2D.new()

    ready = true

    set_size(size)

    connect("body_entered", self, "on_body_entered")
    connect("room_entered", Game, "on_room_entered")

func set_size(new_size):
    size = new_size
    if ready:
        # offset to account for the size of the player body
        $collision.shape.extents = (size * 32) - Vector2(16, 16)
        $collision.position = size * 32
        update()

func get_bounds():
    if ready:
        return [position, position + (size * 64)]
    else:
        return [position, position + get_viewport().size]

func on_body_entered(body):
    if body is Player:
        emit_signal("room_entered", self, body)

# debug visuals
func _draw():
    if Engine.editor_hint:
        var color = Color(1.0, 1.0, 1.0)  # white

        # outline the collision box
        Util.draw_zone(self, color, 16)

