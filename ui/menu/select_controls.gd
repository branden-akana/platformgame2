class_name SelectControls extends MenuSelection


class SelectWalljumpType extends MenuSelection:
    var label_a = "[A] B" 
    var label_b = " A [B]"

    func get_label(): return "walljump style"
    func get_extra():
        if GameState.settings.walljump_type == 0:
            return label_a
        else:
            return label_b

    func get_hint():
        if GameState.settings.walljump_type == 0:
                return "while against a wall, walljump by moving away from it"
        else:
                return "while against a wall, walljump by pressing jump"

    func _toggle():
        if GameState.settings.walljump_type == GameState.WalljumpType.JOYSTICK:
            GameState.settings.walljump_type = GameState.WalljumpType.JUMP
        else:
            GameState.settings.walljump_type = GameState.WalljumpType.JOYSTICK
        GameState.settings.save()

    func on_left(_menu): _toggle()
    func on_right(_menu): _toggle()


var items = [
    SelectKeybinds.new(),
    SelectWalljumpType.new(),
    SelectReturn.new()
]

func get_label(): return "controls"
func get_items(): return items
