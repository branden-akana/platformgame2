class_name SelectExit
extends MenuSelection

func get_label():
    return "exit"

func on_select(_menu):
    GameState.exit()