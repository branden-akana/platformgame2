class_name SelectVideo extends MenuSelection


class Vsync extends MenuSelection:

    var label_on  = "[on] off "
    var label_off = " on [off]"

    func get_label(): return "vsync"

    func get_extra():
        var fps = "   %s FPS" % Engine.get_frames_per_second()
        if OS.is_vsync_enabled():
            return label_on + fps
        return label_off + fps

    func on_left(menu):
        OS.set_use_vsync(not OS.is_vsync_enabled())

    func on_right(menu):
        OS.set_use_vsync(not OS.is_vsync_enabled())


class Lights extends MenuSelection:

    var label_on  = "[on] off"
    var label_off = " on [off]"

    var lights_enabled = true

    func get_label(): return "lights"

    func get_extra():
        if lights_enabled:
            return label_on
        return label_off

    func set_lights(menu, lights):
        lights_enabled = lights
        for node in menu.get_tree().get_nodes_in_group("lights"):
            node.visible = lights_enabled

    func on_left(menu):
        set_lights(menu, !lights_enabled)

    func on_right(menu):
        set_lights(menu, !lights_enabled)

var items = [
    Vsync.new(),
    Lights.new(),
    SelectPalette.new(),
    SelectReturn.new()
]

func get_label(): return "visuals"
func get_items(): return items