extends KinematicBody2D
class_name Runner

signal walking
signal stop_walking
signal land

signal attack

signal enemy_hit     # called when player hit an enemy
signal enemy_killed  # called when player killed an enemy

signal jump
signal dragging
signal died
signal respawned

signal dash

signal airdash
signal airdash_restored

signal walljump_left
signal walljump_right

signal hitstun_start
signal hitstun_end

# constants
# ===========================================

# movement physics params

# general ground movement

export var ACCELERATION = 8000
export var FRICTION = 2000
export var MAX_SPEED = 800
export var FLOOR_SNAP_TOP_MARGIN = 16

# airborne drifting

export var AIR_ACCELERATION = 3000
export var AIR_FRICTION = 1000
export var AIR_MAX_SPEED = 800

# idling / walking

export var WALK_THRESHOLD = 0.2
export var WALK_MAX_SPEED = 250

# airdash

export var AIRDASH_SPEED = 1200  # (mininum) speed at start of airdash
export var AIRDASH_SPEED_END = 600  # speed at end of airdash
export var AIRDASH_LENGTH = 9
export var AIRDASH_WAVELAND_MARGIN = 32

# jumping / gravity

export var JUMPSQUAT_LENGTH = 4  # amount of frames to stay grounded before jumping

export var JUMP_VELOCITY = 1000
export var DASHJUMP_VELOCITY = 800
export var GRAVITY = 2500
export var TERMINAL_VELOCITY = 1250  # maximum downwards velocity
export var FAST_FALL_SPEED = 1250

# dash

# captain falcon: 16
export var DASH_LENGTH = 16  # in frames
export var DASH_SENSITIVITY = 0.3  # how fast you need to tilt the stick to start a dash (0 = more sensitive)

export var DASH_STOP_SPEED = 100  # dash early stop speed

export var DASH_INIT_SPEED = 200  # dash initial speed

export var DASH_ACCELERATION = 20000  # dash acceleration
export var DASH_ACCELERATION_REV = 10000  # dash reverse acceleration

export var DASH_MAX_SPEED = 800  # dash max speed
export var DASH_MAX_SPEED_REV = 1500 # dash reverse max speed (moonwalking)

# buffers (frame window to accept these actions before they are actionable)

export var BUFFER_JUMP = 4
export var BUFFER_AIRDASH = 1

# other consts

const MAX_COINS = 3

# states
# ===========================================

# state machine
var sm = StateMachine.new()

# resources
# ===========================================

# var Coin = load("res://src/Coin.gd")
# var BufferedInput = load("res://src/buffered_input.gd")

# child nodes
# ===========================================

onready var sprite: AnimatedSprite = $sprite
# onready var debug_info = $"/root/main/debug/DebugInfo"
# onready var grapple_line = $"Line2D"
# onready var camera = $"camera"

onready var input: BufferedInput = BufferedInput.new()

# when active, "stun" the player (skip all physics processing)
var stun_timer = Timer.new()

# when active, ignore gravity
var air_stall_timer = Timer.new()

# ref to last thrown coin
var lastcoin = null

# flags
# ======================================================

# current physics tick. restarting sets this back to 0.
var tick: int = 0

# if false, then vertical movement should be processed
var b_is_grounded = true setget set_grounded, is_grounded

# if true, then gravity should be applied
var b_gravity_enabled = false

# current player facing direction
var facing: int = Direction.RIGHT

# if true, attacks don't do any damage
var no_damage = false

# if true, don't play certain effects
var no_effects = false

# if true, runner can hit dead enemies
var ignore_enemy_hp = false

# number of jumps allowed to perform until the runner touches the floor
var jumps_left = 1

# number of dashes allowed to perform until the runner touches the floor
var airdashes_left = 1

var coins_left = MAX_COINS

# state variables
# ======================================================
 
# move runner by this vector every tick
var velocity = Vector2.ZERO

var grapple_initial_vel = Vector2.ZERO  # player's vel when starting a grapple
var grapple_angle = 0.0
var grapple_loose = true
var grapple_dist = 0.0
var grapple_vel = 0.0

func _ready():
    # children setup

    # grapple_line.set_as_toplevel(true)
    # grapple_line.visible = false
    # add_child(grapple_line)

    stun_timer.name = "stun_timer"
    stun_timer.one_shot = true
    add_child(stun_timer)

    air_stall_timer.name = "air_stall_timer"
    air_stall_timer.one_shot = true
    add_child(air_stall_timer)

    #sprite.set_as_toplevel(true)

    $moveset.visible = true

    # state machine setup
    sm.init(self)

    # event setup

    $hurtbox.connect("body_entered", self, "on_hurtbox_entered")

func _exit_tree():
    sprite.queue_free()

func set_input_handler(input_):
    self.input = input_
    for state in sm.states.values():
        state.input = input_

# Respawn the player at the start point of the level
func restart():
    respawn(Game.get_start_point())
    tick = 0

# Respawn the player at a set position
func respawn(pos):
    # print("[runner] setting pos to %s" % pos)
    position = pos
    velocity = Vector2(0, 0)
    sm.goto_idle()
    input.reset()
    emit_signal("respawned")

# throwable grapple points (coins)
# ===========================================

func num_coins():
    var count = 0
    for child in get_children():
        if child is Coin:
            count += 1
    return count

func clear_coins():
    for child in get_children():
        if child is Coin:
            child.queue_free()
            
func get_current_state():
    return sm.current_state

#================================================================================
# UPDATE LOOP (UPDATE VISUALS)
#================================================================================

func _process(_delta):

    # check player direction (for flipping sprites)
    match facing:
        Direction.RIGHT:
            sprite.flip_h = false
        Direction.LEFT:
            sprite.flip_h = true        

    # update sprite animation
    if sm.current_state is IdleState:
        sprite.animation = "idle"
    elif sm.current_state is DashState:
        sprite.animation = "running"
    elif sm.current_state is RunningState:
        sprite.animation = "running"
    elif sm.current_state is AirborneState:
        sprite.animation = "airborne"

    # "grapple":
        # grapple_line.set_default_color(Color(1.0, 1.0, 1.0))
    # "reeling":
        # grapple_line.set_default_color(Color(1.0, 1.0, 1.0))

    # update grapple visuals
    # if state_name in ["grapple", "reeling"]:
    #     grapple_line.visible = true
    #     if lastcoin != null:
    #         grapple_line.set_point_position(0, position)
    #         grapple_line.set_point_position(1, lastcoin.position)
    # else:
    #     grapple_line.visible = false

    # pixel snap the sprite's position
    #sprite.position = Util.gridsnap(position, 4, false)

#================================================================================
# PHYSICS LOOP
#================================================================================

func pre_process(delta):
    pass

func _physics_process(delta):  # update input and physics

    pre_process(delta)

    # pause check
    if Game.game_paused:
        return

    # stun check
    if stun_timer.time_left > 0:
        return

    if is_on_floor():
        if airdashes_left != 1:
            emit_signal("airdash_restored")

        airdashes_left = 1;
        jumps_left = 1;

        if num_coins() >= 1:
            coins_left = MAX_COINS;

    sm.current_state.process(delta)

    # apply gravity to velocity
    if b_gravity_enabled:
        apply_gravity(delta)

    # apply final movement
    velocity = move(delta, velocity)
    # velocity = move_and_slide(velocity, Vector2(0, -1), true)

    tick += 1


func set_grounded(g, emit = true):
    if not b_is_grounded and g and emit:
        emit_signal("land")
    b_is_grounded = g


func is_grounded():
    return b_is_grounded


func move(delta, velocity):

    var new_velocity
    if is_grounded():
        new_velocity = move_and_slide_with_snap(
            Vector2(velocity.x, 0),
            Vector2.DOWN,
            Vector2.UP)
    else:
        new_velocity = move_and_slide_with_snap(
            velocity,
            Vector2.DOWN,
            Vector2.UP)

    # lazy ledge alignment

    var collision = $test_body_bot.move_and_collide(Vector2(velocity.x * delta, 0), true, true, true)
    var top_collision = $test_body_top.move_and_collide(Vector2(velocity.x * delta, 0), true, true, true)
    
    if collision and collision.normal != Vector2.UP and not top_collision:
        var collider = collision.get_collider()
        var shape_idx = collision.get_collider_shape_index()

        var owner_idx = collider.shape_find_owner(shape_idx)
        var tilemap = collider.shape_owner_get_owner(owner_idx)
        #var shape = collider.shape_owner_get_shape(owner_idx, shape_idx)
        
        var tilepos = tilemap.map_to_world(
            tilemap.world_to_map(tilemap.to_local(collision.position))
        ) * 4
        
        # align y-axis to ledge if within margin
        var margin = round(position.y - tilepos.y)
        print("ledge margin = %s" % margin)
        if position.y != tilepos.y and margin <= AIRDASH_WAVELAND_MARGIN:
            position.y = tilepos.y
            position.x += velocity.x * delta
            print("snapped to y=%s" % tilepos.y)

    position = position.round()
    return new_velocity



# Snap to platforms, forcing a grounded state when 
# airdashing slightly under them by a set margin.
func snap_up_to_ground(delta, margin = AIRDASH_WAVELAND_MARGIN):
    # if is_grounded(): ray_length = 2

    # cast a ray down below the runner to try and detect the floor
    var lray = Util.intersect_ray(self, Vector2(-24, 32 - margin), Vector2.DOWN * margin)
    var rray = Util.intersect_ray(self, Vector2(24, 32 - margin), Vector2.DOWN * margin)

    # only apply snap when runner is moving perfectly horizontal
    if velocity.y >= 0 and (lray or rray):
        print("detected below floor")

        # move runner up then down to attempt snap to floor
        if lray:
            position.y = lray.position.y
        else:
            position.y = rray.position.y
        # move_and_collide(Vector2.UP * margin * 2)
        # move_and_slide(Vector2.DOWN * margin * 2 / delta, Vector2.UP)

        # set runner's state if on floor
        # if is_on_floor():
            # set_grounded(true, false)
        return true

    return false


# Make the runner jump. If force is true, ignore how many jumps they have left.
func jump(factor = 1.0, force = false, vel_x = null):

    var axis = input.get_axis()

    if jumps_left == 0 and not force: return

    if not is_on_floor():
        # airborne jump direction switch
        if vel_x:
            velocity.x = vel_x
        elif axis.x > input.PRESS_THRESHOLD:
            velocity.x = MAX_SPEED
        elif axis.x < -input.PRESS_THRESHOLD:
            velocity.x = -MAX_SPEED
        elif axis.y < -input.PRESS_THRESHOLD:
            velocity.x = 0
    else:
        # grounded jump direction switch
        if axis.y < -input.PRESS_THRESHOLD:
            velocity.x = 0

    # if airdashes_left > 0 or force:
    if not force:
    # if not force and not is_on_floor():
        jumps_left -= 1
        # airdashes_left -= 1

    if sm.current_state is AirdashState:
        velocity.y = min(velocity.y, -DASHJUMP_VELOCITY * factor)
    else:
        velocity.y = -JUMP_VELOCITY * factor

    if not force: emit_signal("jump")

    # reset jump animation 
    if sprite.animation == "airborne":
        sprite.frame = 0
        
    sm.goto_airborne()

# Stall the runner (vertically) in the air for a certain number of frames.
func do_air_stall(frames = 18):
    velocity.y = 0
    b_gravity_enabled = false
    air_stall_timer.start(frames * get_physics_process_delta_time())

    yield(air_stall_timer, "timeout")
    b_gravity_enabled = true
    
func apply_gravity(delta):
    if not is_on_floor():
        velocity.y = min(TERMINAL_VELOCITY, velocity.y + (GRAVITY * delta))
        # if input.is_action_just_pressed("key_down") and velocity.y > 0 and velocity.y < GRAVITY:
        # velocity.y = GRAVITY

# Apply acceleration to the runner
func apply_acceleration(delta, x, acceleration, max_speed):

    var in_lower_cap = false
    var in_upper_cap = false

    # check speed caps
    if velocity.x >= -max_speed:
        in_lower_cap = true
    if velocity.x <= max_speed:
        in_upper_cap = true

    # apply acceleration
    if in_lower_cap and x < 0:
        velocity.x = max(-max_speed, velocity.x - acceleration * abs(x) * delta)
    if in_upper_cap and x > 0:
        velocity.x = min(max_speed, velocity.x + acceleration * abs(x) * delta)

    return true

# Apply friction (deceleration) to the runner
func apply_friction(delta, friction = FRICTION):
    if is_on_floor() and abs(velocity.x) > 0:
        emit_signal("dragging")
    velocity.x = move_toward(velocity.x, 0, friction * delta)

# Stun the runner for a specified amount of time
func hitlag(frames):

    # convert frames to seconds
    var time = frames / float(Engine.iterations_per_second)
    stun_timer.start(time)

    emit_signal("hitstun_start")
    sprite.stop()

    yield(stun_timer, "timeout")

    emit_signal("hitstun_end")
    sprite.play()


# Hurt the player.
#
# If the player dies from being hurt, they will respawn at the specified
# respawn point, or the start point if one isn't provided.
func hurt(damage = 100, respawn_point = null):
    _hurt(damage, respawn_point)


func _hurt(damage, respawn_point):
    emit_signal("died")
    if respawn_point:
        respawn(respawn_point)
    else:
        respawn(Game.get_start_point())


# Called when a body intersects this runner's hurtbox.
func on_hurtbox_entered(from):
    # print("hurtbox triggered: %s" % from)
    if "damage" in from:
        hurt(from.damage, from.get_respawn_point())
    else:
        hurt()


# Hit an enemy.
func hit(enemy = null, dmg := 1, contacts := [], stun_frames := 0, airstall := false):

    # airstall player if applicable
    if airstall:
        do_air_stall()

    # hurt enemy
    if not no_damage:
        # print("[moveset] hit for %s damage" % dmg)
        if dmg:
            enemy.hurt(self, dmg)
        else:
            enemy.hurt(self)

        if enemy.health == 0:
            emit_signal("enemy_killed", enemy, contacts)

    # restore airdashes/jumps
    if enemy.health <= 0:
        if airdashes_left != 1: emit_signal("airdash_restored")
        airdashes_left = 1 # restore dash
        #jumps_left = 1  # restore jump

    # put player in hitlag
    hitlag(stun_frames)

    emit_signal("enemy_hit", enemy, contacts)


