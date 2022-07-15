extends Polygon2D


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

