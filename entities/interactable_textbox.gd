extends "res://entities/interactable.gd"

const Textbox = preload("res://ui/textbox.tscn")

@export var lines: Array[String] = ["line 1", "line 2", "line 3"]
@export var preview: bool = false

var _spritefont  # used in editor preview
var textbox

func _ready():
    if Engine.is_editor_hint():
        _spritefont = SpriteLabel.new()
        add_child(_spritefont)

func on_interact():

    for line in lines:
        textbox = GameState.show_textbox(line)
        await textbox.textbox_closed

    await get_tree().process_frame

func on_dismiss():
    if is_instance_valid(textbox):
        textbox.dismiss()

func _process(_delta):
    if Engine.is_editor_hint():
        queue_redraw()

func _draw():
    if Engine.is_editor_hint() and preview:
        _spritefont.draw_text(self, lines[0])


