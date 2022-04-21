class_name SelectOptions
extends MenuSelection

var label = "options"

func get_label():
    return label

func on_select(menu):
    menu.set_items([SelectVsync.new(), SelectReturn.new()])