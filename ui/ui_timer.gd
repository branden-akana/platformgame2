extends Polygon2D


func _ready():
    GameState.connect("practice_mode_changed",Callable(self,"on_practice_mode_changed"))

func on_practice_mode_changed(practice_mode: bool) -> void:
    if practice_mode:
        $big.modulate = Color(0.3, 0.3, 0.3)
        $small.modulate = Color(0.3, 0.3, 0.3)
    else:
        $big.modulate = Color(1.0, 1.0, 1.0)
        $small.modulate = Color(1.0, 1.0, 1.0)

func set_time(m, s, ms) -> void:
    $big.set_text("%02d:%02d" % [m, s])
    $small.set_text("%03d" % [ms])

func set_best_time(best: float) -> void:
    if best < INF:
        $best.set_text("best: %s" % Util.format_time(best))

func set_diff_time(time: float, prev_best: float = INF) -> void:
    if prev_best == INF:
        $best_diff.set_text("")
    else:
        $best_diff.set_text(Util.format_time_diff(time - prev_best))

func reset_best_time() -> void:
    $best.set_text("best: --:--.---")
    $best_diff.set_text("")

