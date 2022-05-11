class_name MainMenu
extends Node2D


# an array of menus, which are
# represented as an array of menu items
var menus = [[
    SelectStart.new(),
    SelectOptions.new(),
    SelectExit.new()
]]
var selected = 0

# if true, slowly rotate between the different color palettes
var b_rotate_palettes = true

onready var title_origin = $title.position

func _ready():
    yield(Game, "post_ready")

    show()

    while b_rotate_palettes:
        var pp = Game.get_display_manager()
        var next_palette = (pp.current_palette + 1) % len(pp.palettes)
        yield(pp.change_palette(next_palette, 5), "completed")

# set the items in the menu, effectively switching menus
func menu_change(items):
    menus.append(items)
    selected = 0

# return to the previous menu if possible
func menu_return():
    if len(menus) > 1:
        # remove last elm of array
        menus.remove(len(menus) - 1)
        selected = 0

# get the active menu (list of items), which
# will be the last menu that was added
func get_active_menu():
    return menus[-1]

func hide():
    visible = false
    b_rotate_palettes = false
    Game.is_in_menu = false
    HUD.get_node("control").visible = true

func show():
    visible = true
    Game.is_in_menu = true
    HUD.get_node("control").visible = false

func _physics_process(delta):
    if not Game.is_in_menu: return

    var items = get_active_menu()

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


