class_name SelectMain
extends MenuSelection

var items = [
    SelectLevel.new(),
    SelectOptions.new(),
    SelectExit.new()
]

func get_label():
    return ""

func get_items():
    return items