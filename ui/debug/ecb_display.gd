extends Line2D


func _ready():
    GameState.connect("debug_mode_changed",Callable(self,"on_debug_mode_changed"))

func on_debug_mode_changed(debug_mode: int) -> void:
    if debug_mode == GameState.DebugMode.HITBOXES:
        visible = true
    else:
        visible = false

func _physics_process(_delta):
    pass
    # if GameState.get_player():
        # set_polygon(GameState.get_player().get_ecb().polygon)

# Set the polygon (with first point added twice for closed shape)
func set_polygon(polygon: PackedVector2Array):
    var pts = []
    for pt in polygon:
        pts.append(pt)
    pts.append(polygon[0])

    self.points = pts


