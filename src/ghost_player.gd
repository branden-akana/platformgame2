extends Runner 
class_name GhostPlayer

var replay_frames = null
var tick = 0

func _ready():
    print("buffer: %s " % buffer)
    no_damage = true

func init(replay_frames_):
    replay_frames = replay_frames_
    print("Replay Loaded (%d frames)" % len(replay_frames))
    reset()

func reset():
    tick = 0
    .reset()

func _physics_process(_delta):

    if game.game_paused:
        return
    
    # read inputs from replay frames
    if replay_frames:
        if tick in replay_frames:
            var input_map = replay_frames[tick]
            for input in input_map:
                self.buffer.trigger_press(input, input_map[input])
            tick += 1
        else:
            reset()
            return

func play_sound(sound, volume = 0.0, pitch = 1.0, force = false):
    pass
