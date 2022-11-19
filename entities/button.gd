extends Area2D

signal button_pressed
signal button_unpressed
signal button_exited

@export var unpress_time = 1.0

var time_left = 0

@onready var unpressed_pos = global_position
@onready var pressed_pos = global_position + (Vector2.DOWN * 8)

var is_player_on = false
var is_pressed = false

var tween: Tween

func _ready():
    set_as_top_level(true)
    $spritetext.set_as_top_level(true)
    $spritetext.modulate.a = 0
    # position -= get_parent().position

    connect("body_entered",Callable(self,"on_body_entered"))
    connect("body_exited",Callable(self,"on_body_exited"))
    connect("button_pressed",Callable(self,"on_button_pressed"))

    global_position = unpressed_pos

# called when the player has walked checked the button
func on_button_pressed():
    time_left = unpress_time

func _physics_process(delta):
    if time_left > 0 and not is_player_on:
        time_left = max(time_left - delta, 0)

    if is_pressed:
        $spritetext.text = "%.3f" % time_left
    else:
        $spritetext.text = "0.000"


func on_body_entered(body):
    if not body is PlayerCharacter:
        return

    if tween.is_active():
        await tween.finished
    else:
        await get_tree().process_frame

    tween.tween_property(self, "global_position",
        unpressed_pos, pressed_pos, 0.1)
    tween.tween_property($spritetext, "modulate:a", $spritetext.modulate.a, 0.5, 0.2)
    

    is_pressed = true
    is_player_on = true
    emit_signal("button_pressed")


func on_body_exited(body):
    if not body is PlayerCharacter:
        return

    if tween.is_active():
        await tween.finished
    else:
        await get_tree().process_frame

    is_player_on = false
    emit_signal("button_exited")

    await get_tree().create_timer(unpress_time).timeout

    if is_player_on == false:
        tween.tween_property(self, "global_position",
            pressed_pos, unpressed_pos, 0.1)
        tween.tween_property($spritetext, "modulate:a", 0.5, 0, 0.2)
        

        is_pressed = false
        emit_signal("button_unpressed")


