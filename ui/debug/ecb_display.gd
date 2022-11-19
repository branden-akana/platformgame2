extends Line2D
@tool

func _ready():
    Game.connect("debug_mode_changed",Callable(self,"on_debug_mode_changed"))

func on_debug_mode_changed(debug_mode: int) -> void:
    if debug_mode == Game.DebugMode.HITBOXES:
        visible = true
    else:
        visible = false

func _physics_process(delta):
    pass
    # if Game.get_player():
        # set_polygon(Game.get_player().get_ecb().polygon)

# Set the polygon (with first point added twice for closed shape)
func set_polygon(polygon: PackedVector2Array):
    var points = []
    for pt in polygon:
        points.append(pt)
    points.append(polygon[0])

    self.points = points


