extends StaticBody2D

signal door_closed
signal door_opened

signal enemies_cleared

@export var door_closed = false
@export var door_open_time = 1.0
@export var door_close_time = 1.0
@export (bool) var focus_when_opening = false
@export (bool) var focus_when_closing = false
@export (bool) var focus_once = true

var close_position: Vector2
var open_position: Vector2

var tween_close = Tween.new()
var tween_open = Tween.new()

var door_focused = false
var door_closed_actual = door_closed

var enemies_cleared = false


func _ready():
    add_child(tween_close)
    add_child(tween_open)
    
    close_position = position
    open_position = close_position + Vector2(0, -32 * 4)

    if door_closed:
        position = close_position
    else:
        position = open_position

    Game.connect("level_restarted",Callable(self,"on_level_restart"))

    if get_node_or_null("button"):
        $button.connect("button_unpressed",Callable(self,"on_button_unpressed"))
        $button.connect("button_pressed",Callable(self,"on_button_pressed"))
    
    connect("enemies_cleared",Callable(self,"on_enemies_cleared"))

func on_level_restart():
    enemies_cleared = false
        
func get_enemies():
    return Game.get_enemies(self)

func is_door_unlocked():
    var linked_enemies_killed = false
    var linked_button_pressed = false

    # linked button is pressed?
    var button = get_node_or_null("button")
    if button:
        linked_button_pressed = button.is_pressed

    return linked_enemies_killed or linked_button_pressed

func on_button_unpressed():
    door_closed = true

func on_button_pressed():
    door_closed = false

func on_enemies_cleared():
    door_closed = false

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
            enemies_cleared = true
            emit_signal("enemies_cleared")

    if door_closed and !door_closed_actual and not tween_close.is_active():
        if door_focused:
            close_door(true, false)
        else:
            close_door(true, focus_when_closing)

    if !door_closed and door_closed_actual and not tween_open.is_active():
        if door_focused:
            open_door(true, false)
        else:
            open_door(true, focus_when_opening)

func close_door(transition = false, focus = true):


    if not door_closed_actual:
        print("[door] closing door")

        door_closed = true

        if tween_open.is_active():
            await tween_open.finished

        if transition:
            if door_closed_actual:
                return

            # letterbox, screen shake, and open door
            tween_close.interpolate_property(
                self, "position", open_position, close_position, door_close_time,
                Tween.TRANS_CUBIC, Tween.EASE_IN)
            tween_close.start()

            if focus:
                # focus camera checked door
                door_focused = true
                Game.set_camera_focus(self)
                await Game.pause_and_lbox_in(0.5).completed

            await tween_close.tween_all_completed
            Game.get_camera_3d().screen_shake(2.0, 0.5)
        else:
            position = close_position

        door_closed_actual = true
        print("[door] door closed")
        emit_signal("door_closed")

        if transition and focus:
            # focus camera back to player
            Game.set_camera_focus(Game.get_player())
            await Game.unpause_and_lbox_out(2.0).completed
    else:
        yield()

func open_door(transition = false, focus = true):


    if door_closed_actual:
        print("[door] opening door")
        door_closed = false

        if tween_close.is_active():
            await tween_close.finished

        if transition:
            if not door_closed_actual:
                return

            # letterbox, screen shake, and open door
            tween_open.interpolate_property(
                self, "position", close_position, open_position, door_open_time,
                Tween.TRANS_CUBIC, Tween.EASE_IN)
            tween_open.start()

            if focus:
                door_focused = true
                # focus camera checked door
                Game.set_camera_focus(self)
                await Game.pause_and_lbox_in(0.5).completed

            await tween_open.tween_all_completed
            Game.get_camera_3d().screen_shake(2.0, 0.5)
        else:
            position = close_position

        door_closed_actual = false
        print("[door] door opened")
        emit_signal("door_opened")

        if transition and focus:
            # focus camera back to player
            Game.set_camera_focus(Game.get_player())
            await Game.unpause_and_lbox_out(2.0).completed
    else:
        yield()

    
