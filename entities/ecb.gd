extends CollisionPolygon2D
tool

enum Type {DIAMOND, BOX}

export (Type) var type = Type.DIAMOND

export (int, 1, 1000) var top = 16  setget set_t, get_t
export (int, 1, 1000) var bottom = 24 setget set_b, get_b
export (int, 1, 1000) var left = 8 setget set_l, get_l
export (int, 1, 1000) var right = 8 setget set_r, get_r

export (float) var ray_inset = 1    # length of ray inside the collision shape
export (float) var ray_outset = 1   # length of ray outside the collision shape


func set_t(top_: int) -> void:
    top = top_
    update_ecb()

func get_t() -> int:
    return top


func set_b(bot_: int) -> void:
    bottom = bot_
    update_ecb()

func get_b() -> int:
    return bottom


func set_l(left_: int) -> void:
    left = left_
    update_ecb()

func get_l() -> int:
    return left


func set_r(right_: int) -> void:
    right = right_
    update_ecb()

func get_r() -> int:
    return right


# Update the shape of the ECB.
func update_ecb():

    if not is_inside_tree(): return

    var ray_length = ray_inset + ray_outset

    $l.position = Vector2(-left + ray_inset, 0)
    $r.position = Vector2(right - ray_inset, 0)
    $t.position = Vector2(0, -top + ray_inset)
    $b.position = Vector2(0, bottom - ray_inset)

    $l.cast_to = Vector2(-ray_length, 0)
    $r.cast_to = Vector2(ray_length, 0)
    $t.cast_to = Vector2(0, -ray_length)
    $b.cast_to = Vector2(0, ray_length)

    var polygon
    if type == Type.DIAMOND:
        # diamond shape
        polygon = [
            Vector2(right, 0),
            Vector2(0, bottom),
            Vector2(-left, 0),
            Vector2(0, -top)
        ]
    else:
        # box shape
        polygon = [
            Vector2(right, -top),
            Vector2(right, bottom),
            Vector2(-left, bottom),
            Vector2(-left, -top)
        ]

    set_polygon(PoolVector2Array(polygon))


# Set the dimensions of the ECB (in pixels).
func set_ecb(top: int, bot: int, left: int, right: int) -> void:
    self.top = top
    self.bottom = bot
    self.left = left
    self.right = right
    update_ecb()


func _test_collision(point) -> bool:
    if get_parent()._check_invalid_platform_collisions():
        return bool(len(Util.intersect_point(self, point, [])))
    else:
        return bool(len(Util.intersect_point(self, point, [], 0b1000000001)))

# These functions test slightly outside the collision shape points

func left_collide_out() -> bool:
    # return _test_collision(polygon[2] + $l.cast_to)
    return $l.is_colliding()

func right_collide_out() -> bool:
    # return _test_collision(polygon[0] + $r.cast_to)
    return $r.is_colliding()

func top_collide_out() -> bool:
    # return _test_collision(polygon[3] + $t.cast_to)
    return $t.is_colliding()

func bottom_collide_out() -> bool:
    # return _test_collision(polygon[1] + $b.cast_to)
    return $b.is_colliding()

# These functions test at exactly the collision shape points

func left_collide() -> bool:
    return _test_collision(polygon[2])

func right_collide() -> bool:
    return _test_collision(polygon[0])

func top_collide() -> bool:
    return _test_collision(polygon[3])

func bottom_collide() -> bool:
    return _test_collision(polygon[1])

# These functions test for any horizontal or vertical collisions

func y_collide() -> bool:
    return top_collide_out() or bottom_collide_out()

func x_collide() -> bool:
    return right_collide_out() or left_collide_out()


func get_left() -> RayCast2D:
    return $l as RayCast2D

func get_right() -> RayCast2D:
    return $r as RayCast2D

func get_top() -> RayCast2D:
    return $t as RayCast2D

func get_bottom() -> RayCast2D:
    return $b as RayCast2D
