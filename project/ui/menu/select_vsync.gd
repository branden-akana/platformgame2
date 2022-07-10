class_name SelectVsync
extends MenuSelection

var label_on  = "vsync:[on] off"
var label_off = "vsync: on [off]"

func get_label():
    if OS.is_vsync_enabled():
        return label_on
    return label_off

func on_left(menu):
    OS.set_use_vsync(not OS.is_vsync_enabled())

func on_right(menu):
    OS.set_use_vsync(not OS.is_vsync_enabled())