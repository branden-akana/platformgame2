extends AnimatedSprite

func _ready():
    Game.connect("paused", self, "on_pause", [true])
    Game.connect("unpaused", self, "on_pause", [false])
    
func on_pause(paused):
    self.playing = not paused
