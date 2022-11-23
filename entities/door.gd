extends StaticBody2D

signal door_closed
signal door_opened

signal enemies_cleared

@export var is_door_closed = false
@export var door_open_time = 1.0
@export var door_close_time = 1.0
@export var focus_when_opening : bool
@export var focus_when_closing : bool
@export var focus_once : bool

var close_position: Vector2
var open_position: Vector2

var tween_close: Tween
var tween_open: Tween

var door_focused = false
var is_door_closed_actual = is_door_closed

var is_enemies_cleared = false


func _ready():
	
	close_position = position
	open_position = close_position + Vector2(0, -32 * 4)

	if is_door_closed:
		position = close_position
	else:
		position = open_position

	# GameState.connect("level_restarted",Callable(self,"on_level_restart"))

	if get_node_or_null("button"):
		$button.connect("button_unpressed",Callable(self,"on_button_unpressed"))
		$button.connect("button_pressed",Callable(self,"on_button_pressed"))
	
	connect("enemies_cleared",Callable(self,"on_enemies_cleared"))

func on_level_restart():
	is_enemies_cleared = false
		
func get_enemies():
	# return GameState.get_current_level().get_enemies(self)
	return 0

func is_door_unlocked():
	var linked_enemies_killed = false
	var linked_button_pressed = false

	# linked button is pressed?
	var button = get_node_or_null("button")
	if button:
		linked_button_pressed = button.is_pressed

	return linked_enemies_killed or linked_button_pressed

func on_button_unpressed():
	is_door_closed = true

func on_button_pressed():
	is_door_closed = false

func on_enemies_cleared():
	is_door_closed = false

func _physics_process(_delta):
	# check if all linked enemies are cleared
	# and emit a signal if they are
	var enemies = get_enemies()
	if len(enemies) > 0:
		var linked_enemies_killed = true
		for enemy in enemies:
			if enemy.health > 0:
				linked_enemies_killed = false
		if linked_enemies_killed:
			is_enemies_cleared = true
			emit_signal("enemies_cleared")

	if is_door_closed and !is_door_closed_actual and not tween_close.is_active():
		if door_focused:
			close_door(true, false)
		else:
			close_door(true, focus_when_closing)

	if !is_door_closed and is_door_closed_actual and not tween_open.is_active():
		if door_focused:
			open_door(true, false)
		else:
			open_door(true, focus_when_opening)

func close_door(transition = false, focus = true):

	if not is_door_closed_actual:
		print("[door] closing door")

		is_door_closed = true

		if tween_open.is_active():
			await tween_open.finished

		if transition:
			if is_door_closed_actual:
				return

			# letterbox, screen shake, and open door
			position = open_position
			tween_close.tween_property(
				self, "position", close_position, door_close_time).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
			tween_close.start()

			if focus:
				# focus camera checked door
				door_focused = true
				# GameState._set_camera_pos(self)
				# await GameState.pause_and_lbox_in(0.5).completed

			await tween_close.tween_all_completed
			GameState.get_camera().screen_shake(2.0, 0.5)
		else:
			position = close_position

		is_door_closed_actual = true
		print("[door] door closed")
		emit_signal("is_door_closed")

		if transition and focus:
			pass
			# focus camera back to player
			# GameState._set_camera_pos(GameState.get_player())
			# await GameState.unpause_and_lbox_out(2.0).completed

func open_door(transition = false, focus = true):

	if is_door_closed_actual:
		print("[door] opening door")
		is_door_closed = false

		if tween_close.is_active():
			await tween_close.finished

		if transition:
			if not is_door_closed_actual:
				return

			# letterbox, screen shake, and open door
			position = close_position
			tween_open.tween_property(
				self, "position", open_position, door_open_time).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
			tween_open.start()

			if focus:
				door_focused = true
				# focus camera checked door
				# GameState._set_camera_pos(self)
				# await GameState.pause_and_lbox_in(0.5).completed

			await tween_open.tween_all_completed
			GameState.get_camera().screen_shake(2.0, 0.5)
		else:
			position = close_position

		is_door_closed_actual = false
		print("[door] door opened")
		emit_signal("door_opened")

		if transition and focus:
			pass
			# focus camera back to player
			# GameState._set_camera_pos(GameState.get_player())
			# await GameState.unpause_and_lbox_out(2.0).completed
	
