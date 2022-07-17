class_name SelectOptions
extends MenuSelection

var label = "options"


class SelectVsync extends MenuSelection:

    var label_on  = "vsync:    [on] off "
    var label_off = "vsync:     on [off]"

    func get_label():
        var fps = "   %s FPS" % Engine.get_frames_per_second()
        if OS.is_vsync_enabled():
            return label_on + fps
        return label_off + fps

    func on_left(menu):
        OS.set_use_vsync(not OS.is_vsync_enabled())

    func on_right(menu):
        OS.set_use_vsync(not OS.is_vsync_enabled())


class SelectWalljumpType extends MenuSelection:
    var label_a = "walljump: [A] B" 
    var label_b = "walljump:  A [B]"
    func get_label():
        if Game.get_player().WALLJUMP_TYPE == 0:
            return label_a
        else:
            return label_b

    func get_hint():
        if Game.get_player().WALLJUMP_TYPE == 0:
                return "while against a wall, walljump by moving away from it"
        else:
                return "while against a wall, walljump by pressing jump"

    func _toggle():
        if Game.get_player().WALLJUMP_TYPE == 0:
            Game.get_player().WALLJUMP_TYPE = 1
        else:
            Game.get_player().WALLJUMP_TYPE = 0

    func on_left(menu): _toggle()
    func on_right(menu): _toggle()


var items = [
    SelectVsync.new(),
    SelectLights.new(),
    SelectWalljumpType.new(),
    SelectPalette.new(),
    SelectReturn.new()
]

func get_label():
    return label

func get_items():
    return items

func on_select(menu):
    menu.set_menu(self)
    menu.get_node("sample").visible = true
    menu.get_node("sample_2").visible = true

func on_return(menu):
    menu.get_node("sample").visible = false
    menu.get_node("sample_2").visible = false
