#================================================================================
# Interactable
#
# A base class for a 2D area that,
# if a character is inside and presses an interact key,
# calls the on_interact() method.
#
# If a character leaves the 2D area or is finished interacting,
# the on_dismiss() method is called.
#================================================================================

class_name Interactable
extends Area2D

signal interacted

var is_player_near = false
var is_interacting = false  # true if in the middle of an interaction

func _ready():
    connect("body_entered",Callable(self,"on_body_enter"))
    connect("body_exited",Callable(self,"on_body_exit"))

func on_body_enter(_body):
    GameState.get_player().get_node("interact_sprite").visible = true
    is_player_near = true

func on_body_exit(_body):
    # print("exited interactable")
    GameState.get_player().get_node("interact_sprite").visible = false
    on_dismiss()
    is_player_near = false
    is_interacting = false

func _process(_delta):
    if is_player_near and Input.is_action_just_pressed("attack"):
        interact()
        
func interact():
    emit_signal("interact")
    if not is_interacting:
        is_interacting = true
        # print("now interacting")
        await on_interact().completed
        # print("no longer interacting")
        is_interacting = false

func on_interact():
    pass

func on_dismiss():
    pass
        
