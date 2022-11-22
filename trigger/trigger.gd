
class_name LevelTrigger extends Area2D

## The color of the editor-only trigger outline
@export var _debug_color: Color = Color.WHITE

## The size of this trigger area (measured in number of screens).
@onready @export var size: Vector2 = Vector2(1, 1) :
    set(new_size):
        size = new_size
        update_size()

##
## Return the size of this trigger area in pixels.
##
func _real_size() -> Vector2:
    return size * Vector2(Constants.SCREEN_SIZE)

##
## Update the size of this collision shape.
##
func update_size():
    $collision.shape.extents = _real_size() / 2.0
    $collision.position = _real_size() / 2.0
    queue_redraw()


## Draw an editor-only outline for this trigger.
func _draw():
    draw_rect(Rect2(0, 0, _real_size().x, _real_size().y), _debug_color, false, 2)
    draw_rect(Rect2(8, 8, _real_size().x - 16, _real_size().y - 16), _debug_color, false, 2)
