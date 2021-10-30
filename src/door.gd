extends StaticBody2D
tool

signal door_closed
signal door_opened

var close_position: Vector2
var open_position: Vector2
var tween

export var door_closed = false


func _ready():
    if Engine.editor_hint:
        return

    tween = Tween.new()
    add_child(tween)
    
    close_position = position
    open_position = close_position + Vector2(0, -32 * 4)

    if door_closed:
        position = close_position
    else:
        position = open_position

func _process(_delta):
    if Engine.editor_hint:
        position = Util.gridsnap(position, 16)
        
func get_enemies():
    return Game.get_enemies(self)

func is_door_unlocked():
    # any linked enemies alive?
    var enemies = get_enemies()
    if len(enemies) > 0:
        for enemy in enemies:
            if enemy.health > 0:
                return false
    return true

func _physics_process(_delta):
    if Engine.editor_hint:
        return

    if is_door_unlocked():
        open_door()

func close_door():

    if not is_door_unlocked() and not door_closed and not tween.is_active():
        tween.interpolate_property(
            self, "position", open_position, close_position, 1.0,
            Tween.TRANS_CUBIC, Tween.EASE_IN)
        tween.start()
        yield(Game.pause_and_lbox_in(0.5), "completed")
        yield(tween, "tween_all_completed")
        Game.get_camera().screen_shake(4.0, 0.5)
        door_closed = true
        emit_signal("door_closed")
        yield(Game.unpause_and_lbox_out(2.0), "completed")
    else:
        yield()

func open_door():

    if door_closed and not tween.is_active():
        Game.set_camera_focus(self)
        tween.interpolate_property(
            self, "position", close_position, open_position, 1.0,
            Tween.TRANS_CUBIC, Tween.EASE_IN)
        tween.start()
        yield(Game.pause_and_lbox_in(0.5), "completed")
        yield(tween, "tween_all_completed")
        Game.get_camera().screen_shake(4.0, 0.5)
        door_closed = false
        emit_signal("door_opened")
        Game.set_camera_focus(Game.get_player())
        yield(Game.unpause_and_lbox_out(2.0), "completed")
    else:
        yield()

    
