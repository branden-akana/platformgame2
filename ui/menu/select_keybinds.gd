class_name SelectKeybinds
extends MenuSelection

class Rebinder extends MenuSelection:
    var label   # the display name of the action
    var action  # the action name (in Godot)
    var listening = false
    func _init(label, action):
        self.label = label
        self.action = action
    func _event_name(event):
        if event is InputEventJoypadButton:
            return Input.get_joy_button_string(event.button_index)
        else:
            return event.as_text()
    func get_label(): return label
    func get_extra(): 
        if listening:
            return "<press new input>"
        else:
            return _event_name(InputMap.get_action_list(action)[0])
    func on_select(menu):
        listening = true
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
                InputMap.action_erase_events(action)
                InputMap.action_add_event(action, event)
                listening = false
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
