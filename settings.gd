class_name Settings extends Resource

const SETTINGS_FILEPATH = "user://settings.res"

# Contains all action bindings. Will be updated on save.
export var action_map: Dictionary

# Contains all level records.
export var records: Dictionary

# Preferred color palette
export var palette: int = 0

# Preferred walljump type
export var walljump_type: int = Runner.WalljumpType.JOYSTICK

func _action_map() -> Dictionary:
    var action_map = {}
    var actions = InputMap.get_actions()

    for action in actions:
        action_map[action] = InputMap.get_action_list(action)

    return action_map

# Apply these settings to the game.
#
func apply():
    for action in action_map.keys():
        InputMap.action_erase_events(action)
        for event in action_map[action]:
            InputMap.action_add_event(action, event)

    Game.get_display_manager().change_palette(palette, 0.0)

    Game.get_player().WALLJUMP_TYPE = walljump_type

func save() -> bool:
    action_map = _action_map()

    var result = ResourceSaver.save(SETTINGS_FILEPATH, self)
    if result == OK:
        print("walljump type: %s" % walljump_type)
        print("saved settings")
        return true
    else:
        var error = str(result)
        match result:
            7: error = "file not found"
            8: error = "bad drive"
            9: error = "bad path"
            10: error = "no permission"
            11: error = "already in use"
            12: error = "can't open"
            13: error = "can't write"
            14: error = "can't read"
            15: error = "unrecognized"
            16: error = "corrupt"
            17: error = "missing dependencies"
            18: error = "eof"
        push_error("cannot save settings: " + error)
        return false

static func load_settings() -> Resource:

    var settings  = ResourceLoader.load(SETTINGS_FILEPATH, "", true)
    var Settings = load("res://settings.gd")

    if settings is Settings:
        settings.apply()
        print("loaded and applied settings")
    else:
        settings = Settings.new()
        print("initialized settings")

    return settings
