extends Area2D
tool

export (PackedScene) var to_level
export (Vector2) var size = Vector2(2, 2) setget set_size

# flag needed for setget
var ready = false

func _ready():
    ready = true
    connect("body_entered", self, "on_body_entered")
    set_size(size)

func _process(delta):
    if Engine.editor_hint:
        # update the position and content of the text
        $spritetext.position = $collision.position + Vector2($collision.shape.extents.x, 0)
        $spritetext.text = to_level.resource_path
        update()

func set_size(new_size):
    size = new_size
    if ready:
        $collision.position = (size * 16)
        $collision.shape.extents = (size * 16)
        update()

func on_body_entered(body):
    if body is Player:
        Game.load_scene(to_level)

func _draw():
    if Engine.editor_hint:
        Util.draw_zone(self, Color(0.0, 1.0, 0.0))  # green

