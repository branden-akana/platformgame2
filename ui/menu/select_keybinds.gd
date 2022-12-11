class_name SelectKeybinds
extends MenuSelection

class KeybindReset extends MenuSelection:

    var label = "Reset Keybinds"

    func get_label(): return label

    func on_select(_menu):
        InputMap.load_from_project_settings()
        label = "Keybinds reset!"

class Rebinder extends MenuSelection:

    var label   # the display name of the action
    var action  # the action name (in Godot)
    var i = 0
    var listening = false

    func _init(label,action):
        self.label = label
        self.action = action

    func _bindings() -> Array:
        return InputMap.action_get_events(action)

    func _idx(i, n): return (i + n + len(_bindings())) % len(_bindings())

    func _event_name(event):
        var name  # name of the button
        var device = event.device
        if event is InputEventJoypadButton:
            # name = JoyButton.keys()[event.button_index]
            # name = Input.get_joy_button_string(event.button_index)
            name = "UNKNOWN"
            return "(JP, %d) %s" % [device, name]
        else:
            name = event.as_text()
            return "(KB) %s" % [name]

    func get_label(): return label
    func get_extra(): 
        if listening:
            return "<press new input>"
        else:
            return "%d/%d: %s" % [i+1, len(_bindings()), _event_name(_bindings()[i])]

    func get_hint():
        return "left/right to choose binding, select to rebind"

    func on_left(_menu): i = _idx(i, -1)
    func on_right(_menu): i = _idx(i, +1)

    func on_select(_menu): listening = true

    func on_update(_menu, _delta) -> bool:
        return !listening
    func on_input(_menu, event: InputEvent) -> bool:
        if listening:
            if (
                # keyboard keys
                event is InputEventKey and event.pressed and !event.echo
                # joypad keys
                or event is InputEventJoypadButton and event.pressed
            ):
                var events = InputMap.action_get_events(action)
                events[i] = event
                InputMap.action_erase_events(action)
                for e in events:
                    InputMap.action_add_event(action, e)
                listening = false
                GameState.settings.save()
                return true
        return false

var items = [
    KeybindReset.new(),
    Rebinder.new("Attack/Select", "attack"),
    Rebinder.new("Jump/Back", "jump"),
    Rebinder.new("Special", "special"),
    Rebinder.new("Airdash", "dodge"),
    Rebinder.new("Reset", "reset"),
    SelectReturn.new()
]


func get_label(): return "keybinds"
func get_items(): return items
func on_select(menu): menu.set_menu(self)
