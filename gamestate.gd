extends Node


# path to the active player
@export_node_path(Character) var player: NodePath

# path to the currently loaded level
@export_node_path(Level) var current_level: NodePath = NodePath("/root/main/level")

# path to the active room
@export_node_path(Node) var current_room: NodePath

# path to the vfx manager
@export_node_path(VFXManager) var vfx_manager = NodePath("/root/main/post_process")

# path to the active camera
@export_node_path(GameCamera) var camera = NodePath("/root/main/camera")

@export var settings: UserSettings

@export_group("GameState Flags")

@export var is_game_paused: bool = false

@export var is_in_menu: bool = false

@export var is_practice_mode_enabled: bool = false

func _ready():
	settings = UserSettings.load_settings()


func get_player() -> Character:
	return $%player as Character
	# return get_node(player)


func get_current_level() -> Level:
	return get_node(current_level)


# Gets n start point of the current level.
func get_start_point(n: int = 0) -> Vector2:
	return get_current_level().get_start_point(n)


# Get the room in focus in the current level.
func get_current_room() -> Node:
	return get_node(current_room)


# Get all rooms in the current level.
func get_all_rooms() -> Array[RoomZone]:
	return get_tree().get_nodes_in_group("room")


func get_display() -> VFXManager:
	return get_node(vfx_manager)


func get_camera_3d() -> GameCamera:
	return get_node(camera)





