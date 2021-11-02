extends TileMap

export (int) var damage = 100
export (NodePath) var respawn_point

# Gets the respawn point to send players after they die to this hazard.
#
# If no respawn point exists, the player will respawn at the start point.
func get_respawn_point() -> Vector2:
    if respawn_point:
        return get_node(respawn_point).global_position
    else:
        return Game.get_start_point()
