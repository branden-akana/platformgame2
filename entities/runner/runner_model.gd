class_name RunnerModel
extends Node3D

func get_animation_player() -> AnimationPlayer:
    return $animation_player as AnimationPlayer

func set_color(color: Color) -> void:
    # $falcon/Skeleton3D/body.material_override.albedo_color = color
    $light.light_color = color

func set_flipped(flipped: bool) -> void:
    if flipped:
        $falcon.rotation_degrees.y = 180
    else:
        $falcon.rotation_degrees.y = 0