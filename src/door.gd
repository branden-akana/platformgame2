extends StaticBody2D

signal door_closed
signal door_opened

var close_position: Vector2
var open_position: Vector2
var tween

export var door_closed = false


func _ready():
    tween = Tween.new()
    add_child(tween)
    
    close_position = position
    open_position = close_position + Vector2(0, -32 * 4)

    if door_closed:
        position = close_position
    else:
        position = open_position
        
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
    if is_door_unlocked():
        open_door(true, false)

func close_door(transition = false):

    if not door_closed:
        print("[door] closing door")
        door_closed = true

        if tween.is_active():
            tween.reset_all()
            tween.stop_all()

        if transition:
            # focus camera on door
            Game.set_camera_focus(self)

            # letterbox, screen shake, and open door
            tween.interpolate_property(
                self, "position", open_position, close_position, 1.0,
                Tween.TRANS_CUBIC, Tween.EASE_IN)
            tween.start()
            yield(Game.pause_and_lbox_in(0.5), "completed")
            yield(tween, "tween_all_completed")
            Game.get_camera().screen_shake(4.0, 0.5)
        else:
            position = close_position

        emit_signal("door_closed")

        if transition:
            # focus camera back to player
            Game.set_camera_focus(Game.get_player())
            yield(Game.unpause_and_lbox_out(2.0), "completed")
    else:
        yield()

func open_door(transition = false, focus = true):

    if door_closed:
        print("[door] opening door")
        door_closed = false

        if tween.is_active():
            tween.reset_all()
            tween.stop_all()

        if transition:
            # letterbox, screen shake, and open door
            tween.interpolate_property(
                self, "position", close_position, open_position, 1.0,
                Tween.TRANS_CUBIC, Tween.EASE_IN)
            tween.start()

            if focus:
                # focus camera on door
                Game.set_camera_focus(self)
                yield(Game.pause_and_lbox_in(0.5), "completed")

            yield(tween, "tween_all_completed")
            Game.get_camera().screen_shake(4.0, 0.5)
        else:
            position = close_position

        emit_signal("door_opened")

        if transition and focus:
            # focus camera back to player
            Game.set_camera_focus(Game.get_player())
            yield(Game.unpause_and_lbox_out(2.0), "completed")
    else:
        yield()

    
