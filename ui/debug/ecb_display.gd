extends Line2D
tool

func _physics_process(delta):
    pass
    # if Game.get_player():
        # set_polygon(Game.get_player().get_ecb().polygon)

# Set the polygon (with first point added twice for closed shape)
func set_polygon(polygon: PoolVector2Array):
    var points = []
    for pt in polygon:
        points.append(pt)
    points.append(polygon[0])

    self.points = points


