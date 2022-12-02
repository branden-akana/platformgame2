@tool
extends Enemy

class PIDController:
	const P_GAIN = 0.25
	const I_GAIN = 4.0

	var enemy: Enemy
	var target: Vector2

	var error_last: Vector2

	func _init(enemy: Enemy) -> void:
		self.enemy = enemy

	func reset():
		error_last = Vector2.ZERO

	func set_target(target: Vector2) -> void:
		self.target = target

	func update():
		var error = target - enemy.position

		var p = error * P_GAIN

		var delta = error - error_last
		error_last = error

		var d = delta * I_GAIN

		enemy.velocity += p + d

	
@export var alpha: float:
	set(a):
		if $svpc:
			$svpc.material.set_shader_parameter("shadow_alpha", a)
		modulate.a = a

@onready var pid := PIDController.new(self)
@onready var spin_rate = 1.0

var hit_tween: Tween

func _ready():
	# rotate 3d cube such that a hexagon is projected
	%cube.rotation.x = deg_to_rad(45)
	%cube.rotation.y = deg_to_rad(35.264)
	%cube.rotation.z = 0

	# set target to original position
	pid.set_target(position)

	enemy_died.connect(on_death)


func _process(delta):
	if not Engine.is_editor_hint():
		%cube.rotate_object_local(%cube.to_local(Vector3.FORWARD).normalized(), delta * spin_rate)


func _physics_process(_delta):
	if not Engine.is_editor_hint():
		pid.update()
		move_and_slide()


func reset() -> void:
	super.reset()
	$animation_player.play("shine")
	if pid:
		position = pid.target
		velocity = Vector2.ZERO
		pid.reset()


func hurt(from, hit_data) -> void:
	super.hurt(from, hit_data)

	var dir_to = from.position.direction_to(self.position)
	dir_to.y = 0
	velocity = dir_to * hit_data["knockback"]
	if hit_tween: hit_tween.kill()
	hit_tween = create_tween().set_parallel(true)
	modulate = Color.WHITE * 10
	spin_rate = 10.0
	hit_tween.tween_property(self, "modulate", Color.WHITE, 0.2)
	hit_tween.tween_property(self, "spin_rate", 1.0, 1.0)


func on_death(_enemy) -> void:
	# fade enemy color
	if not is_visible_when_dead:
		$animation_player.play("death")

