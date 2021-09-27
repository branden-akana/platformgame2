extends Node2D
class_name Game

var time: float = 0.0
var time_best: float = INF
var time_paused: bool = false

var game_paused: bool = false

onready var tween: Tween

func _ready():
    tween = Tween.new()
    add_child(tween)

func get_current_level() -> Level:
    return $"level" as Level
    
func get_camera() -> GameCamera:
    return $"camera" as GameCamera

func get_enemies() -> EnemyGroup:
    return $"enemy_group" as EnemyGroup

func get_player():
    return $"player"

func _physics_process(delta):
    if not time_paused and not game_paused:
        time += delta

    # update HUD timer
    $"hud/timer".text = "%02d:%05.2f" % [floor(time/60.0), fmod(time, 60.0)]
    $"hud/enemy_display".text = "enemies: %d" % get_enemies().num_enemies

    if not tween.is_active() and Input.is_action_just_pressed("ui_home"):
        fade_out(0.2)

func is_best_time():
    return time_paused and time < time_best

# Pause the ingame timer
func pause_timer():
    time_paused = true

# Reset the ingame timer
func reset_timer():
    if is_best_time():
        time_best = time
    time = 0.0
    time_paused = false

func fade_out(time):
    tween.interpolate_property($"hud/fade", "color",
        Color(0.0, 0.0, 0.0, 0.0),
        Color(0.0, 0.0, 0.0, 1.0),
        time, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
    tween.start()



