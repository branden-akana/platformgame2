class_name MovesetPlayer extends AnimationPlayer

## emitted when the current move has connected
signal move_hit

## amount of damage to deal on hit
@export var damage_on_hit: int

## length of player hitlag (self-freezing) on hit
@export var hitlag_ticks_on_hit: int

## strength of gravity dampening (0 - 1)
## 0 = no dampening
## 1 = gravity completely cancelled
@export var grav_damp_strength: float

## if true, dampen gravity at start of move
@export var grav_damp_on_start: bool

## length of gravity dampening on hit
@export var grav_damp_ticks_on_hit: int

@export var knockback: float

## true if the currently move has connected
var hit_detected := false


# Called when the node enters the scene tree for the first time.
func _ready():
	for child in get_node("../elements").get_children():
		if child is Area2D:
			(child as Area2D).area_shape_entered.connect(on_hitbox_entered.bind(child))

	animation_finished.connect(on_animation_finished)


func play_move(anim_name):
	if get_parent().facing == Direction.LEFT:
		get_node("../elements").scale.x = -1
	else:
		get_node("../elements").scale.x = 1
	play(anim_name)
	advance(0)
	hit_detected = false
	if grav_damp_on_start:
		get_parent().gravity_scale = 1.0 - grav_damp_strength

func stop_move():
	current_animation = "RESET"
	seek(0, true)

func on_animation_finished():
	get_parent().gravity_scale = 1.0


func on_hitbox_entered(_area_rid: RID, other: Area2D, other_shape_index: int, hitbox_shape_index: int, hitbox: Area2D):

	var get_shape = func(area: Area2D, shape_index: int) -> CollisionShape2D:
		return area.shape_owner_get_owner(area.shape_find_owner(shape_index))

	var enemy = other.get_parent()

	if (
		not hit_detected and
		enemy is Enemy and
		(enemy as Enemy).can_hurt()
	):
		var hitbox_collider: CollisionShape2D = get_shape.call(hitbox, hitbox_shape_index)
		var other_collider: CollisionShape2D = get_shape.call(other, other_shape_index)

		var contacts = hitbox_collider.shape.collide_and_get_contacts(
			hitbox_collider.get_global_transform(),
			other_collider.shape,
			other_collider.get_global_transform()
		)
		
		if len(contacts) > 1:
			# find contact point closest to player
			var dist = INF
			var closest_contact
			for i in range(len(contacts)):
				var contact = contacts[i]
				var d = get_parent().position.distance_to(contact)
				if d < dist:
					dist = d
					closest_contact = contacts[i]
			contacts = [closest_contact]

		hit_detected = true

		var hit_data = {
			"damage": damage_on_hit,
			"hitlag": hitlag_ticks_on_hit,
			"airstall": grav_damp_ticks_on_hit,
			"knockback": knockback
		}

		move_hit.emit(enemy, hit_data, contacts)




