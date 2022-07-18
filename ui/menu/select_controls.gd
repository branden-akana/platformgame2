class_name SelectControls extends MenuSelection


class SelectWalljumpType extends MenuSelection:
    var label_a = "[A] B" 
    var label_b = " A [B]"

    func get_label(): return "walljump style"
    func get_extra():
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
    SelectKeybinds.new(),
    SelectWalljumpType.new(),
    SelectReturn.new()
]

func get_label(): return "controls"
func get_items(): return items