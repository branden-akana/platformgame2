class_name SelectReturn
extends MenuSelection

func get_label():
    return "back"

func on_select(menu):
    menu.menu_return()