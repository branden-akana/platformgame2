extends Node2D

onready var sounds = {
    "walk": preload("res://assets/footstep06.ogg"),
    "jump": preload("res://assets/jump.ogg"),
    "land": preload("res://assets/land.ogg"),
    "hit":  preload("res://assets/hit_sound.mp3")
}

onready var players = {}

func _ready():
    for sound in sounds:
        players[sound] = AudioStreamPlayer.new()
        players[sound].stream = sounds[sound]
        add_child(players[sound])


func play(sound_name, volume_db = 0.0, pitch_scale = 1.0, loop = false, force = true):
    var player = players[sound_name]
    player.stream.loop = loop
    player.volume_db = volume_db
    player.pitch_scale = pitch_scale
    if force or not player.playing:
        player.play()

func stop(sound_name):
    players[sound_name].playing = false
