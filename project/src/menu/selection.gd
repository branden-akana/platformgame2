#================================================================================
# Represents a menu selection item.
#================================================================================

class_name MenuSelection

# the text that is displayed in the menu
func get_label():
    return "unnamed"

# called when the user selects this item
func on_select(menu):
    pass

# called when the user presses right on this item
func on_right(menu):
    pass

# called when the user presses left on this item
func on_left(menu):
    pass