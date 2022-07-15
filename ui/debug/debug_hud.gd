extends CanvasLayer

var fps_timer

func _ready():
    
    fps_timer = Timer.new()
    fps_timer.one_shot = false
    add_child(fps_timer)
    fps_timer.start(1.0)
    
    fps_timer.connect("timeout", self, "update_fps")
    
func update_fps():
    $fps.text = "%d fps" % Engine.get_frames_per_second()
    
func _physics_process(delta):
    $tick.text = Game.get_player().tick
    $pos_x.text = round(Game.get_player().global_position.x)
    $pos_y.text = round(Game.get_player().global_position.y)
    $vel_x.text = round(Game.get_player().velocity.x)
    $vel_y.text = round(Game.get_player().velocity.y)
    $grounded.text = "grounded: %s" % Game.get_player().is_grounded()

    var ecb = Game.get_player().get_ecb()
    var on = Color(1, 1, 1, 1.0)
    var off = Color(1, 1, 1, 0.5)

    $ray_l.color = on if ecb.left_collide_out() else off
    $ray_r.color = on if ecb.right_collide_out() else off
    $ray_u.color = on if ecb.top_collide_out() else off
    $ray_d.color = on if ecb.bottom_collide_out() else off
    
    
