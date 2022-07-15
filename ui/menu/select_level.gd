class_name SelectLevel
extends MenuSelection

const Level_TestHub = preload("res://levels/test_hub.tscn")
const Level_TestTutorial = preload("res://levels/test_tutorial.tscn")
const Level_Test1 = preload("res://levels/test.tscn")

class Hub extends MenuSelection:
    func get_label(): return "test hub"
    func on_select(menu):
        Game.load_scene(Level_TestHub)
        menu.hide()

class Tutorial extends MenuSelection:
    func get_label(): return "test tutorial"
    func on_select(menu):
        Game.load_scene(Level_TestTutorial)
        menu.hide()

class Test1 extends MenuSelection:
    func get_label(): return "test level 1"
    func on_select(menu):
        Game.load_scene(Level_Test1)
        menu.hide()

var items = [
    Hub.new(),
    Tutorial.new(),
    Test1.new(),
    SelectReturn.new()
]

func get_items():
    return items

func get_label():
    return "select level"

func on_select(menu):
    menu.set_menu(self)