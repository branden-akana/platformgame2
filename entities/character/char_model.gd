
@tool
class_name CharacterModel extends Node2D


@onready var _viewport: SubViewport = $viewport_container/viewport
@onready var _light: DirectionalLight3D = $"viewport_container/viewport/light"
@onready var _model: Node3D = $"viewport_container/viewport/captain"
@onready var _body: MeshInstance3D = $"viewport_container/viewport/captain/falcon/Skeleton3D/body"
@onready var _anim: AnimationPlayer = $"viewport_container/viewport/captain/AnimationPlayer"


@onready @export var material_override: Material :
	set(new_material):
		material_override = new_material
		if _body:
			_body.material_override = new_material

@onready @export var color: Color = Color.WHITE :
	set(new_color): 
		color = new_color
		if _light:
			_light.light_color = new_color
		# $falcon/Skeleton3D/body.material_override.albedo_color = color

@onready @export var flipped: bool = false :
	set(is_flipped):
		flipped = is_flipped
		if is_flipped:
			_model.rotation.y = deg_to_rad(180)
		else:
			_model.rotation.y = 0

func get_model_viewport() -> SubViewport:
	return _viewport

##
## Play an animation from the beginning.
##
func anim_play(anim: String = "", custom_blend := -1.0, custom_speed := 1.0, from_end := false):
	_anim.stop()
	if anim == "":
		_anim.play()
	else:
		_anim.play(anim, custom_blend, custom_speed, from_end)

func anim_stop(reset: bool = true) -> void:
	_anim.stop(reset)

##
## Set the current animation without playing from beginning.
##
func anim_set(anim):
	_anim.current_animation = anim
	#$sprite.animation = anim  # for 2D sprites

func anim_get_current_animation() -> String:
	return _anim.current_animation

func _ready():
	anim_play("idle")

func _physics_process(_delta):
	if "velocity" in get_parent():
		var gravity = Vector3(0, -1, 0)
		var velocity = get_parent().velocity
		if not velocity.is_equal_approx(Vector2.ZERO):
			velocity = velocity * 0.005
			gravity = Vector3(0, velocity.y, -velocity.x)

		$viewport_container/viewport/windbox.gravity_direction = gravity
