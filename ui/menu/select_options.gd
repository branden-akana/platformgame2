class_name SelectOptions
extends MenuSelection

var label = "options"


class SelectVsync extends MenuSelection:

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



var items = [
    SelectControls.new(),
    SelectVsync.new(),
    SelectLights.new(),
    SelectPalette.new(),
    SelectReturn.new()
]

func get_label():
    return label

func get_items():
    return items

func on_select(menu):
    menu.set_menu(self)