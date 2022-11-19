extends Area2D

@onready var Player = load("res://src/Player.gd")

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

@export (Vector2) var triggerSize = Vector2(100, 100)
@export (Vector2) var respawnPoint = Vector2(0, 0)

@onready var trigger = CollisionShape2D.new()

func _body_entered(body):
    if body is Player:
        body.respawn_point = respawnPoint

# Called when the node enters the scene tree for the first time.
func _ready():
    trigger.name = "trigger"
    trigger.shape = RectangleShape2D.new()
    trigger.shape.extents = triggerSize
    add_child(trigger)
    trigger.set_owner(get_tree().edited_scene_root)

    connect("body_entered",Callable(self,"_body_entered"))

    if Engine.editor_hint:
        var point = Marker2D.new()
        add_child(point)
        point.set_owner(get_tree().edited_scene_root)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
    trigger.shape.extents = triggerSize

    if Engine.editor_hint:
        $"Marker2D".global_position = respawnPoint
