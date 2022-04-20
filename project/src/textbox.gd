extends SpriteTextRenderer
tool

signal textbox_closed

export (String) var text = "placeholder text"

# the tick sound when scrolling text
var audio: AudioStreamPlayer = AudioStreamPlayer.new()

# var current_line = 0
var max_chars = 1  # number of characters to show

# line width
var line_width = 20

func _ready():
    audio.stream = load("res://assets/tick.wav")
    audio.pitch_scale = 2
    audio.volume_db = -10
    add_child(audio)

    roll_text()

func show():
    visible = true

# Skip rolling text
func skip():
    # max_chars = len(lines[current_line])
    max_chars = len(text)

# func load_text(lines_):
#     lines = lines_
#     current_line = 0
#     max_chars = 1
#     visible = true
#     roll_text()

func set_text(text_):
    text = text_
    max_chars = 1
    visible = true


func roll_text():
    # while max_chars < len(lines[current_line]):
    while max_chars < len(text):
        audio.play()
        yield(get_tree().create_timer(0.02), "timeout")
        max_chars += 1

# Advance text to the next line
func goto_next_line():
    # if current_line < len(lines) - 1:  # not last line
    #     current_line += 1
    #     max_chars = 1
    # roll_text()
    pass

# If the text is still rolling, skip it.
# If the text was finished rolling, dismiss it.
func advance_text():
    if is_all_text_displayed():
        dismiss()
    else:
        skip()
        # if line_finished():
        #     sm.goto_next_line()
        # else:
        #     skip()
    
# True if the entire line is being displayed
# func line_finished():
#     return max_chars >= len(lines[current_line])

# True if all the text is being displayed
func is_all_text_displayed():
    # return max_chars >= len(lines[current_line]) and current_line >= len(lines) - 1
    return max_chars >= len(text)
    
func dismiss():
    emit_signal("textbox_closed")
    queue_free()

func _process(_delta):
    if not Engine.editor_hint:
        if Input.is_action_just_pressed("grapple"):
            advance_text()
    update()
    
func _draw():
    
    var s
    if Engine.editor_hint:
        # s = lines[current_line]
        s = text
    else:
        # s = lines[current_line].substr(0, max_chars)
        s = text.substr(0, max_chars)

    draw_text(self, s, line_width)
