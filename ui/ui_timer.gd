extends Polygon2D


func set_time(m, s, ms) -> void:
    $big.set_text("%02d:%02d" % [m, s])
    $small.set_text("%03d" % [ms])
