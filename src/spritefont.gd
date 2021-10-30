extends Node2D
class_name SpriteFont

const CHARS = (
    ' !"#$%&' + "'" + '()*+,-./0123456789:;<=>?@' + 
    'ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`' + 
    'abcdefghijklmnopqrstuvwxyz{|}~'
)

export (Vector2) var CHAR_SIZE = Vector2(7, 9)
export (int)     var LINE_LENGTH = 30
export (Texture) var FONT = preload("res://assets/charmap-oldschool_white.png")

var CHAR_MAP = {}

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
func get_rect(x, y):
    return Rect2(CHAR_SIZE * Vector2(x, y) * Config.SCALE, CHAR_SIZE * Config.SCALE)

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

func draw_text(node, text):

    var i = 0  # char position
    var j = 0  # line position

    for c in text:
        if c == "\n":
            i = 0
            j += 1
        else:
            node.draw_texture_rect_region(FONT, get_rect(i, j), get_srcrect(c))
            i += 1
            if i >= LINE_LENGTH:
                i = 0
                j += 1
