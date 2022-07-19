class_name SelectLevel
extends MenuSelection

const Level_TestHub = preload("res://levels/test_area.tscn")
const Level_TestTutorial = preload("res://levels/test_tutorial.tscn")
const Level_Test1 = preload("res://levels/test.tscn")
const Level_Test2 = preload("res://levels/test2.tscn")

class Hub extends MenuSelection:
    func get_label(): return "test area"
    func get_extra():
        return "best: %s" % Game.run_timer.get_record("test area")
    func on_select(menu):
        Game.load_scene(Level_TestHub)
        menu.hide()

class Tutorial extends MenuSelection:
    func get_label(): return "test tutorial"
    func get_extra():
        return "best: %s" % Game.run_timer.get_record("test tutorial")
    func on_select(menu):
        Game.load_scene(Level_TestTutorial)
        menu.hide()

class Test1 extends MenuSelection:
    func get_label(): return "level 1"
    func get_extra():
        return "best: %s" % Game.run_timer.get_record("level 1")
    func on_select(menu):
        Game.load_scene(Level_Test1)
        menu.hide()

class Test2 extends MenuSelection:
    func get_label(): return "level 2 wip"
    func get_extra():
        return "best: %s" % Game.run_timer.get_record("level 2")
    func on_select(menu):
        Game.load_scene(Level_Test2)
        menu.hide()

var items = [
    Tutorial.new(),
    Test1.new(),
    Test2.new(),
    Hub.new(),
    SelectReturn.new()
]

func get_items():
    return items

func get_label():
    return "select level"

func on_select(menu):
    menu.set_menu(self)