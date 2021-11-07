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
    
