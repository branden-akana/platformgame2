extends ColorRect

func _process(delta):
    var xform = get_viewport().canvas_transform
    var pos = xform * Game.get_camera().get_target().global_position
    # print(pos / get_viewport().size)
    #get_material().set_shader_param("focus", pos * 4.0 / get_viewport().size)
