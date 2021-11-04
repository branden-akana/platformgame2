extends Node2D

onready var sounds = {
    "walk": preload("res://assets/walking.ogg"),
    "dash": preload("res://assets/dash.ogg"),
    "jump": preload("res://assets/jump.ogg"),
    "land": preload("res://assets/land.ogg"),
    "hit":  preload("res://assets/hit_sound.mp3"),
    "attack":  preload("res://assets/attack.wav"),
}

onready var players = {}

func _ready():
    for sound in sounds:
        players[sound] = AudioStreamPlayer.new()
        players[sound].stream = sounds[sound]
        add_child(players[sound])


func play(sound_name, volume_db = 0.0, pitch_scale = 1.0, loop = false, force = true):
    var player = players[sound_name]

    if player.stream is AudioStreamSample:
        if loop:
            player.stream.loop_mode = AudioStreamSample.LOOP_FORWARD
        else:
            player.stream.loop_mode = AudioStreamSample.LOOP_DISABLED
    else:
        player.stream.loop = loop

    player.volume_db = volume_db
    player.pitch_scale = pitch_scale
    if force or not player.playing:
        player.play()


func stop(sound_name):
    players[sound_name].playing = false
