extends "res://src/interactable.gd"

const Textbox = preload("res://scenes/textbox.tscn")

export (Array, String) var lines = ["line 1", "line 2", "line 3"]
export (bool) var preview = false

var _spritefont  # used in editor preview
var textbox

func _ready():
    if Engine.editor_hint:
        _spritefont = SpriteFont.new()
        add_child(_spritefont)

func on_interact():

    for line in lines:
        textbox = Game.show_textbox(line)
        yield(textbox, "textbox_closed")

    yield(get_tree(), "idle_frame")

func on_dismiss():
    if is_instance_valid(textbox):
        textbox.dismiss()

func _process(_delta):
    if Engine.editor_hint:
        update()

func _draw():
    if Engine.editor_hint and preview:
        _spritefont.draw_text(self, lines[0])


