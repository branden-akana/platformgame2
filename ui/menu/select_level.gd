class_name SelectLevel
extends MenuSelection

const Level_TestHub = preload("res://levels/lvl_flat.tscn")
const Level_TestTutorial = preload("res://levels/test_tutorial.tscn")
const Level_Test1 = preload("res://levels/test.tscn")

class Hub extends MenuSelection:
	func get_label(): return "dev room"
	func get_extra():
		return "best: %s" % GameState.run_timer.get_record("dev room")
	func on_select(menu):
		GameState.load_scene(Level_TestHub)
		menu.hide()

class Test1 extends MenuSelection:
	func get_label(): return "level 1"
	func get_extra():
		return "best: %s" % GameState.run_timer.get_record("level 1")
	func on_select(menu):
		GameState.load_scene(Level_Test1)
		menu.hide()

var items = [
	Hub.new(),
	Test1.new(),
	SelectReturn.new()
]

func get_items():
	return items

func get_label():
	return "select level"

func on_select(menu):
	menu.set_menu(self)
