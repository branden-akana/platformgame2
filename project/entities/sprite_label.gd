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
const SMALL_FONT = preload("res://assets/spritesheets/spritefont.png")

# a mapping of characters to their location on the spritesheet
const CHARS = (
    ' !"#$%&' + "'" + '()*+,-./0123456789:;<=>?@' + 
    'ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`' + 
    'abcdefghijklmnopqrstuvwxyz{|}~'
)

export (Vector2) var CHAR_SIZE = Vector2(7, 9)
export (Texture) var FONT = SMALL_FONT

var CHAR_MAP = {}

export (int) var line_length = 30
export (String, MULTILINE) var text = "" setget set_text, get_text
export (bool) var bold = false

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
            if char_idx < len(CHARS):
                CHAR_MAP[CHARS[char_idx]] = Vector2(i, j)
                char_idx += 1
            else:
                break

# Get rect to render to
func get_rect(x, y, offset_x = 0, offset_y = 0):
    return Rect2(CHAR_SIZE * Vector2(x, y) * Config.SCALE + Vector2(offset_x, offset_y), CHAR_SIZE * Config.SCALE)

# Get rect from spritesheet for a character
func get_srcrect(c):
    # find coordinate
    var coord
    if c in CHAR_MAP:
        coord = CHAR_MAP[c]
    elif "?" in CHAR_MAP:
        coord = CHAR_MAP["?"]
    else:
        coord = Vector2(1, 13)  # coordinate for ?

    # return coordinate
    return Rect2(CHAR_SIZE * coord, CHAR_SIZE)

func draw_text(text, line_length):
        
    var i = 0  # char position
    var j = 0  # line position

    for c in text:
        if c == "\n":
            i = 0
            j += 1
        else:
            draw_texture_rect_region(FONT, get_rect(i, j, 2, 2), get_srcrect(c))
            if bold:
                draw_texture_rect_region(FONT, get_rect(i, j, 6, 2), get_srcrect(c))
            i += 1
            if i >= line_length:
                i = 0
                j += 1

func _process(delta):
    if Engine.editor_hint:
        update()


func _draw():
    draw_text(text, line_length)

