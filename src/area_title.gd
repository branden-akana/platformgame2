extends Area2D

export var title = "unnamed area"

func _ready():
    connect("body_entered", self, "on_body_entered")
    connect("body_exited", self, "on_body_exited")

func on_body_entered(body):
    if body is Player:
        print("showing title")
        HUD.lbox_in(0.5)
        HUD.area_title_in(title, 0.5)

func on_body_exited(body):
    if body is Player:
        print("unshowing title")
        HUD.lbox_out(0.5)
        HUD.area_title_out(0.5)
