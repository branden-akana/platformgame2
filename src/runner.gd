extends KinematicBody2D
class_name Runner

export var ACCELERATION = 8000
export var AIR_ACCELERATION = 2000
export var MAX_SPEED = 500
export var FRICTION = 3000
export var DODGE_SPEED = 600
export var DODGE_LENGTH = 0.3
export var GRAVITY = 2400
export var TERMINAL_VELOCITY = 1000  # maximum downwards velocity
export var JUMP_VELOCITY = 800

export var COLORS = {
    "default": Color(1.0, 1.0, 1.0),
    "nodashes": Color(0.3, 0.3, 0.3)
}

const MAX_COINS = 3

enum State {
    IDLE,
    RUNNING,
    DASH,
    DODGE,
    GRAPPLING,
    REELING,
    AIRBORNE,
    ATTACK
}

# runner states
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

# sounds
# ===========================================

var sounds = {
    "walk": AudioStreamPlayer.new(),
    "jump": AudioStreamPlayer.new(),
    "land": AudioStreamPlayer.new(),
    "hit": AudioStreamPlayer.new()
}

# resources
# ===========================================

var Coin = load("res://src/Coin.gd")
var InputBuffer = load("res://src/input_buffer.gd")

var ParticleCleaner = preload("res://src/ParticleCleaner.gd")
var DustParticles = preload("res://scenes/particles/DustParticles.tscn")
var JumpParticles = preload("res://scenes/particles/JumpParticles.tscn")
var AirdashEffect = preload("res://scenes/particles/AirdashEffect.tscn")
var DashEffect = preload("res://scenes/particles/DashEffect.tscn")

onready var jump_instance = JumpParticles.instance()
onready var airdash_effect = AirdashEffect.instance()
onready var dash_effect = DashEffect.instance()

var game: Game
# child nodes

var sprite: AnimatedSprite
var buffer: InputBuffer = InputBuffer.new()
var audio_player = AudioStreamPlayer.new()
onready var debug_info = $"/root/World/debug/DebugInfo"
onready var grapple_line = $"Line2D"
onready var camera = $"camera"

# state variables
# ======================================================
 
# if true, attacks don't do anything
var no_damage = false

var airjumps_left = 1
var airdashes_left = 1
var coins_left = MAX_COINS

# current player facing direction
var facing: int = Direction.RIGHT

# ref to last thrown coin
var lastcoin = null

var grapple_initial_vel = Vector2.ZERO  # player's vel when starting a grapple
var grapple_angle = 0.0
var grapple_loose = true
var grapple_dist = 0.0
var grapple_vel = 0.0

var attack_dir = Vector2()

var lastpos = Vector2()
var velocity = Vector2()

# counters for controlling camera shift
var down_held_time = 0.0 
var up_held_time = 0.0

# if > 0, skip physics processing (allow input processing)
var stun_timer: float = 0.0

func _ready():
    self.game = $"/root/World" as Game
    
    # set start position
    position = game.get_current_level().start_point
    
    # initialize all states
    for s in states.values():
        add_child(s)
        s.init(self)

    add_child(audio_player)
    add_child(grapple_line)
    add_child(airdash_effect)

    for key in sounds:
        add_child(sounds[key])

    sprite = $sprite

    sounds["walk"].stream = load("res://assets/footstep06.ogg")
    sounds["walk"].pitch_scale = 0.8
    sounds["walk"].stream.loop = true
    sounds["jump"].stream = load("res://assets/jump.ogg")
    sounds["land"].stream = load("res://assets/land.ogg")
    sounds["hit"].stream = load("res://assets/hit_sound.mp3")

    grapple_line.set_as_toplevel(true)
    grapple_line.visible = false

    sprite.set_as_toplevel(true)
    


func get_state() -> RunnerState:
    if state_name in states:
        return states[state_name]
    return null

# particle effects
# ===========================================

func play_particle_effect(scene, params = {}):
    var instance = scene.instance()
    for key in params:
        instance.set(key, params[key])
    add_child(instance)
    instance.restart()

func stop_particle_effect(_scene):
    for child in get_children():
        if child is ParticleCleaner:
            child.emitting = false

# audio effects
# ===========================================

func play_sound(sound, volume = 0.0, pitch = 1.0, force = false):
    if !sounds[sound].playing or force:
        sounds[sound].volume_db = volume
        sounds[sound].pitch_scale = pitch
        sounds[sound].playing = true

func stop_sound(sound):
    sounds[sound].playing = false

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

func process_friction(delta):
    velocity.x = move_toward(velocity.x, 0, FRICTION * delta)

func process_input(delta):
    if buffer.is_action_pressed("key_down") and is_on_floor():
        down_held_time += delta
    else:
        down_held_time = 0.0

    if buffer.is_action_pressed("key_up") and is_on_floor():
        up_held_time += delta
    else:
        up_held_time = 0.0

func _process(_delta):  # update visuals

    # update player color
    if airdashes_left <= 0:
        sprite.modulate = COLORS["nodashes"]
        # sprite.get_material().set_shader_param("color", Color(0.15, 0.15, 0.15))
    else:
        sprite.modulate = COLORS["default"]
        # sprite.get_material().set_shader_param("color", Color(1.0, 1.0, 1.0))

    # camera panning
    """
    if buffer.is_action_pressed("key_down") and is_on_floor():
        $"Camera2D".set_offset(lerp(Vector2(0, 0), Vector2(0, 80), ease(clamp((down_held_time - 1.0) / 0.5, 0.0, 1.0), -2.8)))
    elif buffer.is_action_pressed("key_up") and is_on_floor():
        $"Camera2D".set_offset(lerp(Vector2(0, 0), Vector2(0, -80), ease(clamp((up_held_time - 1.0) / 0.5, 0.0, 1.0), -2.8)))
    else:
        $"Camera2D".set_offset(Vector2(0, 0))
    """

    # check player direction (for flipping sprites)
    match facing:
        Direction.RIGHT:
            sprite.flip_h = false
        Direction.LEFT:
            sprite.flip_h = true		

    match state_name:
        "running":
            play_sound("walk", -20, 0.8)
        _:
            stop_sound("walk")

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

    sprite.position = ((position / 4.0).floor() * 4.0) + Vector2(0, -8)

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

func set_grapple_line(from, to):
    grapple_line.set_point_position(0, from)
    grapple_line.set_point_position(1, to)

# func attack(direction):

#     var ATTACK_TIME = 0.2
#     var TOTAL_TIME = 0.4
#     var ATTACK_LENGTH = 80
    
#     if state_time == 0:
#         attack_dir = direction.normalized()

#     if state_time <= ATTACK_TIME:
#         velocity.y = 0

#     grapple_line.visible = true
#     grapple_line.set_default_color(Color(1.0, 1.0, 1.0))
#     var endpoint = lerp(position, position + (attack_dir * ATTACK_LENGTH), pow(clamp(state_time / ATTACK_TIME, 0.0, 1.0), 2))
#     set_grapple_line(position, endpoint)
        
#     if state_time >= TOTAL_TIME:
#         reset_state()

func _physics_process(delta):  # update input and physics

    # pause check
    if game.game_paused:
        return

    process_input(delta)

    # stun check
    if stun_timer > 0.0:
        stun_timer -= delta
        if stun_timer <= 0.0:
            post_stun()
        return

    if is_on_floor():
        airdashes_left = 1;
        airjumps_left = 1;

        if num_coins() >= 1:
            coins_left = MAX_COINS;

    var state_ = get_state()
    if state_:
        state_.process(delta)

    # apply velocity
    velocity = velocity.floor()
    # velocity = move_and_slide(velocity, Vector2(0, -1), true)
    velocity = move_and_slide_with_snap(velocity, Vector2(0, 1), Vector2(0, -1), true)

    if self.is_on_floor():
        velocity.y = 1

    lastpos = position

func release_grapple():
    # run at the end of a grapple or reel
    grapple_line.visible = false
    lastcoin.set_color(lastcoin.get_color().darkened(0.5))
    lastcoin = null
    velocity = velocity.normalized() * min(800, velocity.length())  # cap speed out of grapple

func grapple():

    if lastcoin != null:  # grapple

        grapple_initial_vel = velocity
        grapple_dist = lastcoin.position.distance_to(position)
        get_state().set_state("grapple")

    # elif not state in [State.ATTACK]:  # attack
        # attack_dir = input_dir.normalized()
        # set_state(State.ATTACK)

func jump():

    var axis = buffer.get_action_axis()

    if airjumps_left > 0:
        play_particle_effect(JumpParticles)
        play_sound("jump", -10, 1, true)
        airjumps_left -= 1

        if state_name == "airdash":
            velocity.y = -750
        else:
            velocity.y = -900

    if not is_on_floor():
        if axis.x > 0:
            velocity.x = MAX_SPEED
        elif axis.x < 0:
            velocity.x = -MAX_SPEED

func apply_gravity(delta):
    if not is_on_floor():
        velocity.y = min(TERMINAL_VELOCITY, velocity.y + (GRAVITY * delta))
        # if buffer.is_action_just_pressed("key_down") and velocity.y > 0 and velocity.y < GRAVITY:
        # velocity.y = GRAVITY

func reset():
    position = game.get_current_level().start_point
    velocity = Vector2(0, 0)
    get_state().set_state("idle")
    buffer.reset()
    
func stun(length):
    stun_timer = length
    sprite.stop()
    $"attack_f/sprite".stop()
    $"attack_u/sprite".stop()
    $"attack_d/sprite".stop()

func post_stun():
    sprite.play()
    $"attack_f/sprite".play()
    $"attack_u/sprite".play()
    $"attack_d/sprite".play()
    
# Apply friction (deceleration) to the runner
func apply_friction(delta):
    if abs(velocity.x) > 0:
        play_particle_effect(DustParticles)
    velocity.x = move_toward(velocity.x, 0, FRICTION * delta)

func apply_velocity(_delta):
    velocity = velocity.floor()
    velocity = move_and_slide(velocity, Vector2(0, -1), true)
    # velocity = move_and_slide_with_snap(velocity, Vector2(0, 1), Vector2(0, -1), true)
    debug_info.text = "speed: %3.2f (x=%3.2f, y=%3.2f)\nstate: %s" % [velocity.length(), velocity.x, velocity.y, State.keys()[state]]


