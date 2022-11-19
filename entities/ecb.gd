@tool
class_name CharECB extends CollisionPolygon2D


enum Type {DIAMOND, BOX}

@onready var l: RayCast2D = $l
@onready var r: RayCast2D = $r
@onready var t: RayCast2D = $t
@onready var b: RayCast2D = $b

@export_group("Dimensions")

@onready @export var type: Type = Type.DIAMOND

@onready @export_range(1, 1000) var top: int = 64 :
	get:
		return top
	set(top_):
		top = top_
		update_ecb()

@onready @export_range(1, 1000) var bottom: int = 92 :
	get:
		return bottom
	set(bottom_):
		bottom = bottom_
		update_ecb()

@onready @export_range(1, 1000) var left: int = 32 :
	get:
		return left
	set(left_):
		left = left_
		update_ecb()

@onready @export_range(1, 1000) var right: int = 32 :
	get:
		return right
	set(right_):
		right = right_
		update_ecb()

@export_group("Raycasts")

@onready @export var ray_inset: float = 1.0 :  # length of ray inside the collision shape
	get:
		return ray_inset
	set(inset):
		ray_inset = inset
		update_ecb()

@onready @export var ray_outset: float = 1.0 :   # length of ray outside the collision shape
	get:
		return ray_outset
	set(outset):
		ray_outset = outset
		update_ecb()



# Update the shape of the ECB.
func update_ecb():

	if not is_inside_tree(): return

	var ray_length = ray_inset + ray_outset

	l.position = Vector2(-left + ray_inset, 0)
	r.position = Vector2(right - ray_inset, 0)
	t.position = Vector2(0, -top + ray_inset)
	b.position = Vector2(0, bottom - ray_inset)

	l.target_position = Vector2(-ray_length, 0)
	r.target_position = Vector2(ray_length, 0)
	t.target_position = Vector2(0, -ray_length)
	b.target_position = Vector2(0, ray_length)

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

	set_polygon(PackedVector2Array(polygon))


# Set the dimensions of the ECB (in pixels).
func set_ecb(top: int, bot: int, left: int, right: int) -> void:
	self.top = top
	self.bottom = bot
	self.left = left
	self.right = right
	update_ecb()


# func _test_collision(point) -> bool:
# 	if get_parent()._check_invalid_platform_collisions():
# 		return bool(len(Util.intersect_point(self, point, [])))
# 	else:
# 		return bool(len(Util.intersect_point(self, point, [], 0b1000000001)))


# These functions test slightly outside the collision shape points

func left_collide_out() -> bool:
	# return _test_collision(polygon[2] + l.target_position)
	return l.is_colliding()

func right_collide_out() -> bool:
	# return _test_collision(polygon[0] + r.target_position)
	return r.is_colliding()

func top_collide_out() -> bool:
	# return _test_collision(polygon[3] + t.target_position)
	return t.is_colliding()

func bottom_collide_out() -> bool:
	# return _test_collision(polygon[1] + b.target_position)
	return b.is_colliding()

# These functions test at exactly the collision shape points

# func left_collide() -> bool:
# 	return _test_collision(polygon[2])

# func right_collide() -> bool:
# 	return _test_collision(polygon[0])

# func top_collide() -> bool:
# 	return _test_collision(polygon[3])

# func bottom_collide() -> bool:
# 	return _test_collision(polygon[1])

# These functions test for any horizontal or vertical collisions

func y_collide() -> bool:
	return top_collide_out() or bottom_collide_out()

func x_collide() -> bool:
	return right_collide_out() or left_collide_out()


func get_left() -> RayCast2D:
	return l as RayCast2D

func get_right() -> RayCast2D:
	return r as RayCast2D

func get_top() -> RayCast2D:
	return t as RayCast2D

func get_bottom() -> RayCast2D:
	return b as RayCast2D
