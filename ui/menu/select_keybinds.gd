class_name SelectKeybinds
extends MenuSelection

class Rebinder extends MenuSelection:

    var label   # the display name of the action
    var action  # the action name (in Godot)
    var i = 0
    var listening = false

    func _init(label, action):
        self.label = label
        self.action = action

    func _bindings() -> Array:
        return InputMap.get_action_list(action)

    func _idx(i, n): return (i + n + len(_bindings())) % len(_bindings())

    func _event_name(event):
        var name  # name of the button
        var device = event.device
        if event is InputEventJoypadButton:
            name = Input.get_joy_button_string(event.button_index)
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

    func on_left(menu): i = _idx(i, -1)
    func on_right(menu): i = _idx(i, +1)

    func on_select(menu): listening = true

    func on_update(menu, delta) -> bool:
        return !listening
    func on_input(menu, event: InputEvent) -> bool:
        if listening:
            if (
                # keyboard keys
                event is InputEventKey and event.pressed and !event.echo
                # joypad keys
                or event is InputEventJoypadButton and event.pressed
            ):
                var events = InputMap.get_action_list(action)
                events[i] = event
                InputMap.action_erase_events(action)
                for e in events:
                    InputMap.action_add_event(action, e)
                listening = false
                Game.settings.save()
                return true
        return false

var items = [
    Rebinder.new("Attack/Select", "grapple"),
    Rebinder.new("Jump/Back", "key_jump"),
    Rebinder.new("Airdash", "key_dodge"),
    Rebinder.new("Reset", "reset"),
    SelectReturn.new()
]


func get_label(): return "keybinds"
func get_items(): return items
func on_select(menu): menu.set_menu(self)
