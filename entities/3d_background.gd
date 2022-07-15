extends Node2D
tool

export (float) var scroll_rate = 1.0
export (float) var parallax = 0.5

onready var origin: Vector2 = position

func _ready():
    $sprite.set_as_toplevel(true)

func _process(delta):

    var camera
    if Game and Game.has_method("get_camera"):
        camera = Game.get_camera()

    var box_1 = $viewport/spatial/csg_box
    var box_2 = $viewport/spatial/csg_box_2

    var z = scroll_rate * delta
    if camera:
        var x = origin.x + camera.focus.x * parallax * 0.0005
        $sprite.position = origin + camera.focus

        box_1.material.uv1_offset.x = fmod(x, 1.0)
        box_2.material.uv1_offset.x = fmod(x, 1.0)

    box_1.material.uv1_offset.z = fmod(box_1.material.uv1_offset.z + z, 1.0)
    box_2.material.uv1_offset.z = fmod(box_2.material.uv1_offset.z + z, 1.0)

    
    
    