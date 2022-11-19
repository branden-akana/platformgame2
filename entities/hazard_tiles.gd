extends TileMap

@export var damage: int = 100

# Gets the respawn point to send players after they die to this hazard.
#
# If no respawn point exists, the player will respawn at the start point.
func get_respawn_point() -> Vector2:
    if get_node_or_null("respawn"):
        return $"respawn".global_position
    elif not Engine.is_editor_hint():
        return GameState.get_start_point()
    else:
        return Vector2.ZERO
