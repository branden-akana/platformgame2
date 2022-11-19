class_name SelectOptions
extends MenuSelection

var label = "options"


class SelectPractice extends MenuSelection:

    func get_label(): return "practice mode"

    func get_extra():
        if GameState.is_practice_mode_enabled:
            return "[checked] unchecked "
        else:
            return " checked [unchecked]"

    func get_hint(): return "if enabled, be able to see and hit dead enemies. disables timer."

    func on_left(menu): GameState.toggle_practice_mode()
    func on_right(menu): GameState.toggle_practice_mode()


class SelectReset extends MenuSelection:

    var cleared = false

    func get_label(): return "clear records"

    func get_hint(): 
        if cleared:
            return "all records cleared"
        else:
            return "select to erase all level records"

    func on_select(menu):
        GameState.settings.records = {}
        cleared = true


var items = [
    SelectVideo.new(),
    SelectControls.new(),
    SelectPractice.new(),
    SelectReset.new(),
    SelectReturn.new()
]

func get_label():
    return label

func get_items():
    return items

func on_select(menu):
    menu.set_menu(self)