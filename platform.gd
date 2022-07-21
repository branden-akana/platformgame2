extends StaticBody2D
tool


func _process(delta):
    var points = PoolVector2Array([
        $collision_shape_2d.shape.a,
        $collision_shape_2d.shape.b,
    ])
    $line_2d.points = points
    $line_2d_2.points = points
