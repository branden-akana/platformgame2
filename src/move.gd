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

export (bool) var reload setget start

export (NodePath) var runner_path
export (int) var frame_length = 30
export (Array, Resource) var hitbox_data

var runner
var playing: bool = false
var paused: bool = false
var frame = 0

# if true, flip this move horizontally
var flipped = false setget set_flipped

# if true, this move hit something
var hit_detected = false

# move properties
# =================================

# how long to put the player in hitstun on hit (in frames, from time of hit)
export (int) var stun_length = 6

# if true, stops the player's vertical velocity and stops applying gravity
export var cancel_gravity_on_hit = true

# how long to cancel gravity on hit (in frames, from start of the move)
export var cancel_gravity_length = 18

func _ready():
    if not Engine.editor_hint:
        runner = get_node(runner_path)
        runner.connect("hitstun_start", self, "pause")
        runner.connect("hitstun_start", self, "resume")

    for hitbox in get_children():
        if hitbox is Area2D:
            hitbox.connect("area_shape_entered", self, "on_hitbox_entered", 
                [hitbox])

func _physics_process(delta):
    if frame > frame_length:
        stop(false)

    elif playing and not paused:

        # print("[move] %s: frame %s" % [name, frame])

        for i in range(len(hitbox_data)):
            var hitbox = get_node(String(i))

            if frame == hitbox_data[i].frame_start:
                # print("[move] %s: enabling hitbox" % name)
                hitbox.monitoring = true
                hitbox.get_node("collision").disabled = false
                hitbox.modulate = Color(4.0, 0.0, 0.0)

            elif frame == hitbox_data[i].frame_end + 1:
                # print("[move] %s: disabling hitbox" % name)
                hitbox.monitoring = false
                hitbox.get_node("collision").disabled = true
                hitbox.modulate = Color(1.0, 1.0, 1.0)
                
            # apply gravity when:
            if (
                # no hit was detected yet or
                not hit_detected or
                # the move doesn't cancel gravity or
                not cancel_gravity_on_hit or
                # the move cancels gravity and is within the frame window
                cancel_gravity_on_hit and frame > cancel_gravity_length
                ):
                    runner.apply_gravity(delta)

        frame += 1

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
    if(hitbox.monitoring and playing and target is Enemy and (target.health > 0 or runner.ignore_enemy_hp)):
        # var hitbox_col = hitbox.get_node("collision")
        # print("[move] %s: hitbox %s hit enemy (%s)" % [name, hitbox.name, hitbox_col.disabled])

        # on hit behavior
        if cancel_gravity_on_hit:
            runner.velocity.y = 0
        # runner.jumps_left = 1  # restore jump
        runner.airdashes_left = 1 # restore dash
        runner.stun(stun_length)

        # on hit effects
        if not runner.no_effects:
            var target_shape = Util.get_shape(target, target_shape_id)
            var hitbox_shape = Util.get_shape(hitbox, hitbox_shape_id)
            var contacts = Util.get_collision_contacts(
                target, target_shape,
                hitbox, hitbox_shape
            )
            if len(contacts):
                var effect = Effects.play_anim(Effects.HitEffect)
                effect.position = (contacts[0] / 4).floor() * 4
                effect.frame = 0

        # on hit damage
        if not runner.no_damage:
            target.damage(runner)

            if target.health == 0:
                var effect = Effects.play(Effects.HitParticles)
                effect.position = target.position
                effect.direction = runner.position.direction_to(target.position)

            Game.get_camera().screen_shake(1.0, 0.2)
            runner.emit_signal("hit")

        hit_detected = true
        emit_signal("move_hit")

func start(__ = null):
    # print("[move] %s: started" % name)
    # reset flags
    frame = 0
    playing = true
    hit_detected = false

    # reset sprite
    $sprite.visible = true
    $sprite.frame = 0  # restart animation

    # flip if directed to the left
    set_flipped(runner.facing == Direction.LEFT)

    
    resume()

func pause():
    paused = true
    $sprite.stop()

func resume():
    paused = false
    $sprite.play()

func stop(forced = true):
    if playing:
        frame = 0
        playing = false
        $sprite.visible = false
        pause()
        if forced:
            # print("[move] %s: finished" % name)
            emit_signal("move_finished")
        else:
            # print("[move] %s: stopped" % name)
            emit_signal("move_stopped")
