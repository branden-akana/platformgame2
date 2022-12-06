extends ColorRect

func _process(_delta):
    var xform = get_viewport().canvas_transform
    var _pos = xform * GameState.get_camera().get_target().global_position
    # print(pos / get_viewport().size)
    #get_material().set_shader_parameter("focus", pos * 4.0 / get_viewport().size)
