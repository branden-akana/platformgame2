#===============================================================================
# Move
#
# Contains scripting for a move (i.e. attacks, specials).
# This script contains:
# - animation
# - frame data
#===============================================================================

extends Node2D
tool

signal move_started
signal move_hit
signal move_finished
signal move_stopped  # called when the move ended manually

# reference to the runner containing this move
onready var runner = $"../.."

# if true, this move is currently playing
export var playing: bool = false
export var tick = 0

# if true, flip this move horizontally
var flipped = false setget set_flipped

# if true, this move hit something
var hit_detected = false

# move properties
# =================================

export (int) var move_length = 30
export (int) var move_damage = 1

export (Array, Dictionary) var move_hitboxes = [
    {
        "start": 0,
        "end": 4,
    }
]

# how long to put the player in hitstun on hit (in frames, from time of hit)
export (int) var hitlag_on_hit = 6

# the animation to play when performing this move
export (String) var animation = "attack"

# if true, stops the player's vertical velocity at the start
export (bool) var disable_gravity_on_start = false

# if greater than 0, the amount of ticks gravity will be disabled on hit
export (int) var disable_gravity_on_hit = 18


func _ready():
    runner = $"../.."
    runner.connect("stun_start", self, "pause")
    runner.connect("stun_end", self, "resume")

    for hitbox in get_children(): if hitbox is Area2D:
        # emit "move_hit" if anything enters a hitbox
        hitbox.connect("area_shape_entered", self, "on_hitbox_entered", [hitbox])


func start():
    print("[move] %s: started" % name)
    # reset flags
    tick = 0
    playing = true
    hit_detected = false

    # play move animation
    $sprite.visible = true
    $sprite.frame = 0  # restart animation

    runner.play_animation(animation)

    # flip if directed to the left
    if runner:
        set_flipped(runner.facing == Direction.LEFT)
    
    resume()


func pause():
    playing = false
    $sprite.stop()


func resume():
    playing = true
    $sprite.play()


func stop(forced = true):
    tick = 0
    playing = false
    $sprite.visible = false
    pause()
    if forced:
        # print("[move] %s: finished" % name)
        emit_signal("move_finished")
    else:
        # print("[move] %s: stopped" % name)
        emit_signal("move_stopped")

    # disable all hitboxes
    for i in range(len(move_hitboxes)):
        disable_hitbox(i)

    property_list_changed_notify()

func enable_hitbox(i: int):

    var hitbox = get_node(str(i))
    hitbox.monitoring = true
    hitbox.get_node("collision").set_deferred("disabled", false)

func disable_hitbox(i: int):

    var hitbox = get_node(str(i))
    hitbox.monitoring = false
    hitbox.get_node("collision").set_deferred("disabled", true)

func move_update(delta):

    if tick > move_length:
        stop(false)

    elif playing:

        # print("[move] %s: frame %s" % [name, frame])

        # disable gravity at start of move
        if disable_gravity_on_start and tick == 0:
            if runner:
                runner.velocity.y = 0

        for i in range(len(move_hitboxes)):

            var hitbox = get_node(String(i))

            # enable hitbox if inside window
            if tick == move_hitboxes[i]["start"]:
                # print("[move] %s: enabling hitbox" % name)
                enable_hitbox(i)
                hitbox.modulate = Color(4.0, 0.0, 0.0)

            # disable hitbox if outside window
            elif tick == move_hitboxes[i]["end"] + 1:
                # print("[move] %s: disabling hitbox" % name)
                disable_hitbox(i)
                hitbox.modulate = Color(1.0, 1.0, 1.0)

            $sprite.modulate.a = 1 - ((tick - 12) / float(move_length))

        tick += 1
        property_list_changed_notify()

func _physics_process(delta):
    if Engine.editor_hint:
        move_update(delta)

# Flip the move horizontally.
func set_flipped(flip):
    flipped = flip
    if flipped:
        scale = Vector2(-1, 1)
    else:
        scale = Vector2(1, 1)

# called when an object enters a hitbox
#
# target: the object that was hit
# hitbox: the collision of the hitbox that was triggered
func on_hitbox_entered(area_id, target: Area2D, target_shape_id, hitbox_shape_id, hitbox: Area2D):
    # if not runner.fsm._current_state() !=  and hitbox.monitoring:
        # print("[warning] attack hitbox triggered outside of attack state!!")
        # hitbox.monitoring = false

    if(hitbox.monitoring and playing and target is Enemy and (target.health > 0 or runner.ignore_enemy_hp)):
        print("[move] %s: hitbox %s hit enemy" % [name, hitbox.name])

        # compute contact points
        var target_shape = Util.get_shape(target, target_shape_id)
        var hitbox_shape = Util.get_shape(hitbox, hitbox_shape_id)
        var contacts = Util.get_collision_contacts(
            target, target_shape,
            hitbox, hitbox_shape
        )

        emit_signal("move_hit")
        runner.hit(target, move_damage, contacts, hitlag_on_hit, disable_gravity_on_hit)
        hit_detected = true
