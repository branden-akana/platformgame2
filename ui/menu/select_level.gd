class_name SelectLevel
extends MenuSelection

const LEVEL_DIR := "res://levels/"

class LevelSelection extends MenuSelection:
	var packed_scene: PackedScene
	var name: String = "UNKNOWN"
	func _init(packed_scene: PackedScene):
		self.packed_scene = packed_scene
		
		# try to find name of level
		var state = packed_scene.get_state()
		for i in range(state.get_node_count()):
			for j in range(state.get_node_property_count(i)):
				var vname := state.get_node_property_name(i, j)
				var val = state.get_node_property_value(i, j)
				if vname == "level_name":
					name = val

	func get_label(): return name
	func on_select(menu):
		GameState.load_level(packed_scene)
		menu.menu_hide()

var items = [
	SelectReturn.new()
]

func _init():
	# read and add all .tscn files in level folder
	var dir = DirAccess.open(LEVEL_DIR)
	if dir:
		dir.list_dir_begin()
		while true:
			var path := dir.get_next()
			if path == "": break

			if path.get_extension() == "tscn":
				# items.append(LevelSelection.new(path))
				items.append(LevelSelection.new(load(LEVEL_DIR + path)))
		dir.list_dir_end()

func get_items():
	return items

func get_label():
	return "select level"

func on_select(menu):
	menu.set_menu(self)
