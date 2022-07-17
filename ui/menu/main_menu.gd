class_name MainMenu
extends Node2D


# an array of menus, which are
# represented as an array of menu items
var menus = [
    SelectMain.new(),
]
var selected = 0
var current: MenuSelection = null

# if true, slowly rotate between the different color palettes
var b_rotate_palettes = true

# the tick sound when scrolling text
var asp: AudioStreamPlayer = AudioStreamPlayer.new()

onready var title_origin = $title.position

func _ready():
    asp.stream = load("res://assets/tick.wav")
    asp.pitch_scale = 2
    asp.volume_db = -10
    add_child(asp)

    yield(Game, "post_ready")
    show()

    while b_rotate_palettes:
        var pp = Game.get_display_manager()
        var next_palette = (pp.current_palette + 1) % len(pp.palettes)
        yield(pp.change_palette(next_palette, 5), "completed")

# set the items in the menu, effectively switching menus
func set_menu(selection):
    menus.append(selection)
    selected = 0

# return to the previous menu if possible
func menu_return():
    if len(menus) > 1:
        # remove last elm of array
        menus.remove(len(menus) - 1)
        if current: current.on_return(self)
        selected = 0

# get the active menu (list of items), which
# will be the last menu that was added
func get_active_menu():
    return menus[-1]

func hide():
    visible = false
    b_rotate_palettes = false
    Game.is_in_menu = false
    Game.unpause(Game.PauseRequester.MENU)
    HUD.get_node("control").visible = true

func show():
    visible = true
    Game.is_in_menu = true
    Game.pause(Game.PauseRequester.MENU)
    HUD.get_node("control").visible = false

func _physics_process(delta):
    if not Game.is_in_menu: return

    var items = get_active_menu().get_items()

    if Input.is_action_just_pressed("key_down"):
        selected = (selected + 1) % len(items)
        asp.play()
    
    if Input.is_action_just_pressed("key_up"):
        selected = (selected + len(items) - 1) % len(items)
        asp.play()

    if Input.is_action_just_pressed("key_left"):
        items[selected].on_left(self)
        asp.play()

    if Input.is_action_just_pressed("key_right"):
        items[selected].on_right(self)
        asp.play()

    if Input.is_action_just_pressed("grapple"):
        var item = items[selected]
        item.on_select(self)
        current = item
        asp.play()

    # move title
    $title.position = Util.gridsnap(Vector2(title_origin.x, title_origin.y + ((sin(OS.get_ticks_msec() * 0.001) + 1) * 8)), 4)

    # update menu text
    var text = ""
    var extra = ""
    for i in len(items):
        var item = items[i]
        text += "  " + item.get_label() + "\n"
        extra += item.get_extra() + "\n"
            
    $selections.text = text
    $extras.text = extra
    $hint.text = items[selected].get_hint()

    var tween = Util.create_tween(self)
    tween.interpolate_property($highlight, "position",
        $highlight.position,
        selected * Vector2(0, 46), 0.05
    )
    tween.start()
    Util.await_tween(tween)


