extends AnimatedSprite2D

func _ready():
    Game.connect("paused",Callable(self,"on_pause").bind(true))
    Game.connect("unpaused",Callable(self,"on_pause").bind(false))
    
func on_pause(paused):
    self.playing = not paused
