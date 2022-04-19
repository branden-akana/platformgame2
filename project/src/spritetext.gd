extends Node2D
tool

export (String) var text = "" setget set_text

onready var spritefont = SpriteFont.new()

func set_text(text_):
    text = String(text_)
    update()
    
func _ready():
    add_child(spritefont)
    
func _draw():
    spritefont.draw_text(self, text)
    
