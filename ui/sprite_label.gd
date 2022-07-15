#================================================================================
# Sprite Label
#
# The spritesheet equivalent of a Label.
# This Node uses a spritesheet image instead of a font file.
#================================================================================
extends Node2D
class_name SpriteLabel
tool

# a pre-loaded default spritesheet
export (Texture) var sprite_sheet

# a mapping of characters to their location on the spritesheet
export (String, MULTILINE) var characters

# size of each character (in pixels)
export (Vector2) var char_size

export (int) var line_length = 30

export (String, MULTILINE) var text = "" setget set_text, get_text

export (bool) var bold = false

var char_map = {}

func set_text(text_):
    text = String(text_)
    update()
    
func get_text():
    return text

func _ready():
    # generate character map
    var char_idx = 0
    for j in range(0, 6):
        for i in range(0, 18):
            if char_idx < len(characters):
                char_map[characters[char_idx]] = Vector2(i, j)
                char_idx += 1
            else:
                break

# Get rect to render to
func get_rect(x, y, offset_x = 0, offset_y = 0):
    return Rect2(char_size * Vector2(x, y) * Config.SCALE + Vector2(offset_x, offset_y), char_size * Config.SCALE)

# Get rect from spritesheet for a character
func get_srcrect(c):
    # find coordinate
    var coord
    if c in char_map:
        coord = char_map[c]
    elif "?" in char_map:
        coord = char_map["?"]
    else:
        coord = Vector2(1, 13)  # coordinate for ?

    # return coordinate
    return Rect2(char_size * coord, char_size)

func draw_text(text, line_length):
        
    var i = 0  # char position
    var j = 0  # line position

    for c in text:
        if c == "\n":
            i = 0
            j += 1
        else:
            draw_texture_rect_region(sprite_sheet, get_rect(i, j, 2, 2), get_srcrect(c))
            if bold:
                draw_texture_rect_region(sprite_sheet, get_rect(i, j, 6, 2), get_srcrect(c))
            i += 1
            if i >= line_length:
                i = 0
                j += 1

func _process(delta):
    if Engine.editor_hint:
        update()


func _draw():
    draw_text(text, line_length)

