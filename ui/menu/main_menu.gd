#@tool
class_name MainMenu extends Node2D


# an array of menus, which are
# represented as an array of menu items
@onready var menus: Array = [
	SelectMain.new(),
]
var selected = 0
var current: MenuSelection = null

# if true, skip the next _physics_process() call
var b_skip_process = false

# if true, slowly rotate between the different color palettes
var b_rotate_palettes = true

# the tick sound when scrolling text
var asp: AudioStreamPlayer = AudioStreamPlayer.new()

@onready var title_origin = $title.position

var cursor_tween: Tween

func _ready():
	asp.stream = load("res://assets/sounds/tick.wav")
	asp.pitch_scale = 2
	asp.volume_db = -10
	add_child(asp)

	await GameState.post_ready
	menu_hide()

	# while b_rotate_palettes:
	# 	var pp = GameState.get_display()
	# 	var next_palette = (pp.current_palette + 1) % len(pp.palettes)
	# 	await pp.change_palette(next_palette, 5)

func _current_menu() -> MenuSelection:
	return menus[-1] as MenuSelection

func _current_items() -> Array:
	return _current_menu().get_items()

func _update_current_menu() -> void:
	if current: current.on_return(self)
	current = _current_menu()
	current.on_enter(self)
	selected = 0

# set the items in the menu, effectively switching menus
func set_menu(selection):
	menus.append(selection)
	_update_current_menu()

# return to the previous menu if possible
func menu_return():
	if len(menus) > 1:
		# remove_at last elm of array
		menus.remove_at(len(menus) - 1)
		_update_current_menu()

func menu_hide():
	visible = false
	b_rotate_palettes = false
	GameState.is_in_menu = false
	GameState.unpause(GameState.PauseRequester.MENU)
	GameState.get_hud().get_node("ui_timer").visible = true
	print("hiding menu")

func menu_show():
	selected = 0
	menus = menus.slice(0, 1)
	GameState.is_in_menu = true
	GameState.pause(GameState.PauseRequester.MENU)
	visible = true
	GameState.get_hud().get_node("ui_timer").visible = false
	print("showing menu")

func _input(event):
	var items = _current_items()
	if items[selected].on_input(self, event):
		b_skip_process = true


func _physics_process(delta):
	if not GameState.is_in_menu: return

	if b_skip_process:
		b_skip_process = false
		return

	var items = _current_items()

	if not items[selected].on_update(self, delta): return

	if Input.is_action_just_pressed("key_down"):
		items[selected].on_unhover(self)
		selected = (selected + 1) % len(items)
		items[selected].on_hover(self)
		asp.play()
	
	if Input.is_action_just_pressed("key_up"):
		items[selected].on_unhover(self)
		selected = (selected + len(items) - 1) % len(items)
		items[selected].on_hover(self)
		asp.play()

	if Input.is_action_just_pressed("key_left"):
		items[selected].on_left(self)
		asp.play()

	if Input.is_action_just_pressed("key_right"):
		items[selected].on_right(self)
		asp.play()

	if Input.is_action_just_pressed("attack"):
		var item = items[selected]
		item.on_select(self)
		asp.play()

	if Input.is_action_just_pressed("jump"):
		menu_return()
		asp.play()

	# move title
	$title.position = Util.gridsnap(Vector2(title_origin.x, title_origin.y + ((sin(Time.get_ticks_msec() * 0.001) + 1) * 8)), 4)

	# update menu text
	var text = ""
	var extra = ""
	var extra_2 = ""
	var extra_3 = ""

	for i in len(items):
		var item = items[i]
		text += "  " + item.get_label() + "\n"
		if item.get_extra() is Array:
			extra += item.get_extra()[0] + "\n"
			extra_2 += item.get_extra()[1] + "\n"
			extra_3 += item.get_extra()[2] + "\n"
		else:
			extra += item.get_extra() + "\n"
			extra_2 += "\n"
			extra_3 += "\n"
			
	$subtitle.text = _current_menu().get_label()
	$selections.text = text
	$extras.text = extra
	$extras_2.text = extra_2
	$extras_3.text = extra_3
	$hint.text = items[selected].get_hint()

	if cursor_tween:
		cursor_tween.kill()

	cursor_tween = create_tween()
	cursor_tween.tween_property($highlight, "position",
		selected * Vector2(0, 46), 0.05
	)
	await cursor_tween.finished


