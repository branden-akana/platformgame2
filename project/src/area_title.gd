extends Area2D
tool

export var title = "unnamed area"
export (Vector2) var extents = Vector2(8, 2) setget set_extents, get_extents

func _ready():
    connect("body_entered", self, "on_body_entered")
    connect("body_exited", self, "on_body_exited")
    
func set_extents(new_extents):
    extents = new_extents
    $collision_shape_2d.shape.extents = extents * 32
    
func get_extents():
    return extents

func on_body_entered(body):
    if body is Player:
        print("showing title")
        HUD.lbox_in(0.5)
        HUD.area_title_in(title, 0.5)

func on_body_exited(body):
    if body is Player:
        print("unshowing title")
        HUD.lbox_out(0.5)
        HUD.area_title_out(0.5)
