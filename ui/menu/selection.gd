#================================================================================
# Represents a menu selection item.
#================================================================================

class_name MenuSelection

# the text that is displayed in the menu
func get_label():
    return ""

# text that is displayed checked the right side of the menu
func get_extra():
    return ""

# text that is displayed checked the bottom of the menu
func get_hint():
    return ""

# called when the user selects this item
func on_select(menu):
    if len(get_items()): menu.set_menu(self)
    
# called when the cursor hovers over this item
func on_hover(_menu):
    pass

# called when the cursor leaves this item
func on_unhover(_menu):
    pass

# if this item is a menu, is called when this menu is entered
func on_enter(_menu):
    pass

# if this item is a menu, is called when this menu is left
func on_return(_menu):
    pass

# get this selection's new menu items. if this array is empty,
# this selection isn't a menu.
func get_items() -> Array:
    return []

# called when the user presses right checked this item
func on_right(_menu):
    pass

# called when the user presses left checked this item
func on_left(_menu):
    pass

func on_update(_menu, _delta) -> bool:
    return true

func on_input(_menu, _event: InputEvent) -> bool:
    return false
