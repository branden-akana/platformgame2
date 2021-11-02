extends TileMap

export (int) var damage = 100

# Gets the respawn point to send players after they die to this hazard.
#
# If no respawn point exists, the player will respawn at the start point.
func get_respawn_point() -> Vector2:
    if get_node_or_null("respawn"):
        return $"respawn".global_position
    elif not Engine.editor_hint:
        return Game.get_start_point()
    else:
        return Vector2.ZERO
