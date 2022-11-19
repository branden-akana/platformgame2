extends AnimatedSprite2D

func _ready():
    GameState.connect("paused",Callable(self,"on_pause").bind(true))
    GameState.connect("unpaused",Callable(self,"on_pause").bind(false))
    
func on_pause(paused):
    self.playing = not paused
