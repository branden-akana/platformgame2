class_name SelectOptions
extends MenuSelection

var label = "options"

func get_label():
    return label

func on_select(menu):
    menu.menu_change([SelectVsync.new(), SelectPalette.new(), SelectReturn.new()])