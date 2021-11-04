extends KinematicBody2D
class_name Runner

signal walking
signal stop_walking
signal land
signal hit
signal jump
signal dash
signal dragging
signal died
signal respawned

signal walljump_left
signal walljump_right

# constants
# ===========================================

# movement physics params

export var ACCELERATION = 8000
export var FRICTION = 3000
export var MAX_SPEED = 800

export var AIR_ACCELERATION = 3000
export var AIR_FRICTION = 1000
export var AIR_MAX_SPEED = 700

export var FAST_FALL_SPEED = 2500

export var DODGE_SPEED = 600
export var DODGE_LENGTH = 0.3

export var JUMP_VELOCITY = 800
export var GRAVITY = 2400
export var TERMINAL_VELOCITY = 1000  # maximum downwards velocity

# other consts

const MAX_COINS = 3

# states
# ===========================================

var states = {
    "idle": IdleState.new(),
    "dash": DashState.new(),
    "running": RunningState.new(),
    "airborne": AirborneState.new(),
    "airdash": AirdashState.new(),
    "jumpsquat": JumpsquatState.new(),

    "shootcoin": ShootCoinState.new(),
    "grapple": GrappleState.new(),
    "reeling": ReelingState.new(),

    "attack": AttackState.new()
}

var state_name = "idle"
var state setget , get_state  # the state the player is in

# resources
# ===========================================

# var Coin = load("res://src/Coin.gd")
var InputBuffer = load("res://src/input_buffer.gd")

# child nodes
# ===========================================

onready var sprite: AnimatedSprite = $sprite
# onready var debug_info = $"/root/main/debug/DebugInfo"
onready var grapple_line = $"Line2D"
# onready var camera = $"camera"

onready var buffer: InputBuffer = InputBuffer.new()

# when active, "stun" the player (skip all physics processing)
var stun_timer = Timer.new()

# ref to last thrown coin
var lastcoin = null

# flags
# ======================================================

# current physics tick. restarting sets this back to 0.
var tick: int = 0

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
    
    # add_child(grapple_line)
    add_child(stun_timer)
    stun_timer.one_shot = true

    # sprite setup
    sprite.set_as_toplevel(true)

    # state setup
    for s in states.values():
        s.init(self)
        add_child(s)

    grapple_line.set_as_toplevel(true)
    grapple_line.visible = false

    # connect signals to particle effects
    connect("jump", Effects, "play", [Effects.Jump, self]) 
    connect("dragging", Effects, "play", [Effects.Dust, self])
    connect("land", Effects, "play", [Effects.Land, self]) 
    connect("walljump_left", Effects, "play", [Effects.WallJumpRight, self]) 
    connect("walljump_right", Effects, "play", [Effects.WallJumpLeft, self]) 

    $hurtbox.connect("body_entered", self, "on_hurtbox_entered")

func _exit_tree():
    sprite.get_parent().remove_child(sprite)
    sprite.queue_free()

func get_state() -> RunnerState:
    if state_name in states:
        return states[state_name]
    return null

func set_input_buffer(buffer_):
    self.buffer = buffer_
    for state in states.values():
        state.buffer = buffer_

func get_current_conditions():
    var conditions = RunnerInitialState.new()
    conditions.position = position
    conditions.velocity = velocity
    conditions.state_name = state_name
    conditions.buffer = buffer.duplicate()
    return conditions

# Respawn the player at the start point of the level
func restart():
    respawn(Game.get_start_point())
    tick = 0

# Respawn the player at a set position
func respawn(pos):
    # print("[runner] setting pos to %s" % pos)
    position = pos
    velocity = Vector2(0, 0)
    get_state().set_state("idle")
    buffer.reset()
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
    match state_name:
        "idle":
            sprite.animation = "idle"
        "dash":
            sprite.animation = "running"
        "running":
            sprite.animation = "running"
        "airborne":
            sprite.animation = "airborne"
        "grapple":
            grapple_line.set_default_color(Color(1.0, 1.0, 1.0))
        "reeling":
            grapple_line.set_default_color(Color(1.0, 1.0, 1.0))

    # update grapple visuals
    if state_name in ["grapple", "reeling"]:
        grapple_line.visible = true
        if lastcoin != null:
            grapple_line.set_point_position(0, position)
            grapple_line.set_point_position(1, lastcoin.position)
    else:
        grapple_line.visible = false

    # pixel snap the sprite's position
    sprite.position = Util.gridsnap(position, 4)

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
        airdashes_left = 1;
        jumps_left = 1;

        if num_coins() >= 1:
            coins_left = MAX_COINS;

    var state_ = get_state()
    if state_:
        state_.process(delta)

    # apply velocity
    velocity = move_and_slide_with_snap(velocity, Vector2(0, 1), Vector2(0, -1), true)
    # velocity = move_and_slide(velocity, Vector2(0, -1), true)

    tick += 1

# Make the runner jump. If force is true, ignore how many jumps they have left.
func jump(factor = 1.0, force = false, vel_x = null):

    var axis = buffer.get_action_axis()

    if jumps_left > 0 or force:
        emit_signal("jump")
        if not force:
            jumps_left -= 1

        if state_name == "airdash":
            velocity.y = -750 * factor
        else:
            velocity.y = -950 * factor

    if not is_on_floor():
        if vel_x:
            velocity.x = vel_x
        elif axis.x > buffer.PRESS_THRESHOLD:
            velocity.x = MAX_SPEED
        elif axis.x < -buffer.PRESS_THRESHOLD:
            velocity.x = -MAX_SPEED
        elif axis.y < -buffer.PRESS_THRESHOLD:
            velocity.x = 0
        
    state.set_state("airborne")

    
func apply_gravity(delta):
    if not is_on_floor():
        velocity.y = min(TERMINAL_VELOCITY, velocity.y + (GRAVITY * delta))
        # if buffer.is_action_just_pressed("key_down") and velocity.y > 0 and velocity.y < GRAVITY:
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
func stun(length):

    stun_timer.start(length)

    sprite.stop()
    $"attack_f/sprite".stop()
    $"attack_u/sprite".stop()
    $"attack_d/sprite".stop()

    yield(stun_timer, "timeout")

    sprite.play()
    $"attack_f/sprite".play()
    $"attack_u/sprite".play()
    $"attack_d/sprite".play()

# Hurt the player.
#
# If the player dies from being hurt, they will respawn at the specified
# respawn point, or the start point if one isn't provided.
func hurt(damage = 100, respawn_point = null):
    emit_signal("died")
    if respawn_point:
        respawn(respawn_point)
    else:
        respawn(Game.get_start_point())

# Called when a body intersects this runner's hurtbox.
func on_hurtbox_entered(from):
    # print("hurtbox triggered: %s" % from)
    hurt(from.damage, from.get_respawn_point())

