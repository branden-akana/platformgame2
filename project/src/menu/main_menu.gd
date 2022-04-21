class_name MainMenu
extends Node2D


var items = [
    SelectStart.new(),
    SelectOptions.new(),
    SelectExit.new()
]
var selected = 0

# if true, slowly rotate between the different color palettes
var b_rotate_palettes = true

onready var title_origin = $title.position

func _ready():
    Game.is_in_menu = true
    Game.reparent_to_fg3(self)
    HUD.hide()

    yield(get_tree().root, "ready")

    while b_rotate_palettes:
        var pp = Game.get_post_processor()
        var next_palette = (pp.current_palette + 1) % len(pp.palettes)
        yield(pp.change_palette(next_palette, 5), "completed")

# set the items in the menu, effectively switching menus
func set_items(_items):
    items = _items
    selected = 0

# reset the items in the menu to the main menu items
func reset_items():
    items = [
        SelectStart.new(),
        SelectOptions.new(),
        SelectExit.new()
    ]

func hide():
    visible = false
    b_rotate_palettes = false
    Game.is_in_menu = false

func show():
    visible = true
    Game.is_in_menu = true

func _physics_process(delta):
    if not Game.is_in_menu: return

    if Input.is_action_just_pressed("key_down"):
        selected = (selected + 1) % len(items)
    
    if Input.is_action_just_pressed("key_up"):
        selected = (selected + len(items) - 1) % len(items)

    if Input.is_action_just_pressed("key_left"):
        items[selected].on_left(self)

    if Input.is_action_just_pressed("key_right"):
        items[selected].on_right(self)

    if Input.is_action_just_pressed("grapple"):
        var item = items[selected]
        item.on_select(self)

    # move title
    $title.position = Util.gridsnap(Vector2(title_origin.x, title_origin.y + ((sin(OS.get_ticks_msec() * 0.001) + 1) * 8)), 4)

    # update menu text
    var text = ""
    for i in len(items):
        var item = items[i]
        if i == selected:
            text += "# " + item.get_label() + "\n"
        else:
            text += "  " + item.get_label() + "\n"
            
    $label.text = text


