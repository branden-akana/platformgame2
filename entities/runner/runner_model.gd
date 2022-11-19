
@tool
class_name CharacterModel extends Node2D


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


## Play an animation from the beginning.
##
func anim_play(anim, from_end = false, force = false):
	if _anim.current_animation != anim or force:
		# 3D model
		var speed = 1.0  # playback speed
		var seek = 0.0   # seconds in anim to skip to

		if anim == "attack_f":
			seek = 0.5

		_anim.play(anim, -1, speed, from_end)
		_anim.seek(seek)


## Set the current animation without playing from beginning.
##
func anim_set(anim):
	_anim.current_animation = anim
	#$sprite.animation = anim  # for 2D sprites

func _ready():
	anim_play("idle")
