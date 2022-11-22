## Controls the tilemaps used for levels.
class_name LevelTilemap extends Node2D


func _ready():
	# hide certain tiles when in-game

	# hazard trigger (red spike)
	var data := _get_detail_tile_data(0, 8)
	data.modulate.a = 0.0

	GameState.debug_mode_changed.connect(on_debug_mode_changed)

##
## Retrieve the TileData from the detail TileSet.
##
func _get_detail_tile_data(x: int, y: int) -> TileData:
	return ($map_8 as TileMap).tile_set.get_source(0).get_tile_data(Vector2i(x, y), 0)

func on_debug_mode_changed(debug_mode: GameState.DebugMode) -> void:
	# hazard trigger (red spike)
	var data := _get_detail_tile_data(0, 8)

	if debug_mode == GameState.DebugMode.NORMAL:
		data.modulate.a = 0.0
	else:
		data.modulate.a = 1.0
		

