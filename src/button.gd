extends Area2D

signal button_pressed
signal button_unpressed
signal button_exited

export var unpress_time = 1.0

var time_left = 0

onready var unpressed_pos = global_position
onready var pressed_pos = global_position + (Vector2.DOWN * 8)

var is_player_on = false
var is_pressed = false

var tween = Tween.new()
var timer = Timer.new()

func _ready():
    set_as_toplevel(true)
    $spritetext.set_as_toplevel(true)
    $spritetext.modulate.a = 0
    # position -= get_parent().position

    add_child(tween)
    add_child(timer)

    connect("body_entered", self, "on_body_entered")
    connect("body_exited", self, "on_body_exited")
    connect("button_pressed", self, "on_button_pressed")

    global_position = unpressed_pos

# called when the player has walked on the button
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
    if not body is Player:
        return

    if tween.is_active():
        yield(tween, "tween_completed")
    else:
        yield(get_tree(), "idle_frame")

    tween.interpolate_property(self, "global_position",
        unpressed_pos, pressed_pos, 0.1)
    tween.interpolate_property($spritetext, "modulate:a", $spritetext.modulate.a, 0.5, 0.2)
    tween.start()

    is_pressed = true
    is_player_on = true
    timer.stop()
    emit_signal("button_pressed")


func on_body_exited(body):
    if not body is Player:
        return

    if tween.is_active():
        yield(tween, "tween_completed")
    else:
        yield(get_tree(), "idle_frame")

    is_player_on = false
    emit_signal("button_exited")

    timer.start(unpress_time)

    yield(timer, "timeout")

    if is_player_on == false:
        tween.interpolate_property(self, "global_position",
            pressed_pos, unpressed_pos, 0.1)
        tween.interpolate_property($spritetext, "modulate:a", 0.5, 0, 0.2)
        tween.start()

        is_pressed = false
        emit_signal("button_unpressed")


