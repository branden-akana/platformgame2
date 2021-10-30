extends KinematicBody2D

const ACCELERATION = 8000
const AIR_ACCELERATION = 2000
const MAX_SPEED = 500
const FRICTION = 4000
const DODGE_SPEED = 600
const DODGE_LENGTH = 0.3
const GRAVITY = 2400
const TERMINAL_VELOCITY = 1000  # maximum downwards velocity

const JUMP_VELOCITY = 800

const MAX_COINS = 3

onready var debug_info = $"../debug/DebugInfo"
onready var grapple_line = $"Line2D"
onready var body = $"Polygon2D"

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

var audio_player = AudioStreamPlayer.new()

var sounds = {
    "walk": AudioStreamPlayer.new(),
    "jump": AudioStreamPlayer.new(),
    "land": AudioStreamPlayer.new()
}

var Coin = load("res://src/Coin.gd")

# particle base class
var ParticleCleaner = preload("res://Effects/ParticleCleaner.gd")

# landing particle effect
var dust_scene = preload("res://Effects/DustParticles.tscn")
onready var dust_instance = dust_scene.instance()

# jumping particle effect
var jump_scene = preload("res://Effects/JumpParticles.tscn")
onready var jump_instance = jump_scene.instance()

# dash particle effect
var airdash_effect_scene = preload("res://Effects/AirdashEffect.tscn")
onready var airdash_effect = airdash_effect_scene.instance()

var dash_effect_scene = preload("res://Effects/DashEffect.tscn")
onready var dash_effect = dash_effect_scene.instance()

# coin
var coin_scene = preload("res://Coin.tscn")
var lastcoin = null
var coins_left = MAX_COINS

var respawn_point = Vector2(0, 0)

var state = State.IDLE  # the state the player is in
var state_time = 0  # amount of seconds spent in this state

var airjumps_left = 1
var dodges_left = 1
var dodge_direction = Vector2.ZERO;

var grapple_initial_vel = Vector2.ZERO  # player's vel when starting a grapple
var grapple_angle = 0.0
var grapple_loose = true
var grapple_dist = 0.0
var grapple_vel = 0.0

var attack_dir = Vector2()

var lastpos = Vector2()
var velocity = Vector2()
var input_dir = Vector2()  # the input direction
var pre_velocity = Vector2.ZERO
var dodge_vector = Vector2.DOWN
var is_grounded = false

var facing = "right"

var down_held_time = 0.0 
var up_held_time = 0.0

var input_buffer = {
    "key_right": 0,
    "key_left": 0
}

func _ready():
    add_child(dust_instance)
    add_child(jump_instance)
    add_child(airdash_effect)
    add_child(dash_effect)

    add_child(audio_player)

    for key in sounds:
        add_child(sounds[key])

    sounds["walk"].stream = load("res://assets/footstep06.ogg")
    sounds["walk"].pitch_scale = 0.8
    sounds["walk"].stream.loop = true
    sounds["jump"].stream = load("res://assets/jump.ogg")
    sounds["land"].stream = load("res://assets/land.ogg")

    grapple_line.set_as_toplevel(true)
    grapple_line.visible = false

# particle effects
# ===========================================

func play_particle_effect(scene, params = {}):
    var instance = scene.instance()
    for key in params:
        instance.set(key, params[key])
    add_child(instance)
    instance.restart()

func stop_particle_effect(scene):
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

func set_state(_state):
    state = _state
    state_time = 0

func reset_state():
    if is_on_floor():
        play_particle_effect(dust_scene)
        if input_dir.x != 0:
            set_state(State.RUNNING)
        else:
            set_state(State.IDLE)
    else:
        set_state(State.AIRBORNE)

func is_state_just_started(_state):
    return state == _state and state_time == 0.0

func process_friction(delta):
    velocity.x = move_toward(velocity.x, 0, FRICTION * delta)

func process_input(delta):
    for action in ["key_left", "key_right", "key_dodge"]:
        if !(action in input_buffer):
            input_buffer[action] = 0
            # input_buffer[action] = 100

        # if Input.get_action_strength(action) <= 0.5:
        # 	input_buffer[action] = 100
        # elif Input.get_action_strength(action) >= 0.5:
        # 	if input_buffer[action] == 100:
        # 		input_buffer[action] = 0
        # 	else:
        # 		input_buffer[action] += delta

        if Input.is_action_just_pressed(action):
            input_buffer[action] = 0
        else:
            input_buffer[action] += delta

    if Input.is_action_pressed("key_down") and is_on_floor():
        down_held_time += delta
    else:
        down_held_time = 0.0

    if Input.is_action_pressed("key_up") and is_on_floor():
        up_held_time += delta
    else:
        up_held_time = 0.0

func is_pressed(action, buffer):
    return input_buffer[action] <= buffer

func _process(delta):

    # dash color
    if dodges_left <= 0:
        $"AnimatedSprite".get_material().set_shader_param("color", Color(0.4, 0.4, 0.4))
        # body.set_color(Color(0.6, 0.6, 0.6))
    else:
        $"AnimatedSprite".get_material().set_shader_param("color", Color(1.0, 1.0, 1.0))
        # body.set_color(Color(1.0, 1.0, 1.0))

    # camera panning
    if Input.is_action_pressed("key_down") and is_on_floor():
        $"Camera2D".set_offset(lerp(Vector2(0, 0), Vector2(0, 80), ease(clamp((down_held_time - 1.0) / 0.5, 0.0, 1.0), -2.8)))
    elif Input.is_action_pressed("key_up") and is_on_floor():
        $"Camera2D".set_offset(lerp(Vector2(0, 0), Vector2(0, -80), ease(clamp((up_held_time - 1.0) / 0.5, 0.0, 1.0), -2.8)))
    else:
        $"Camera2D".set_offset(Vector2(0, 0))

    if velocity.x > 0:
        facing = "right"
    elif velocity.x < 0:
        facing = "left"	

    var sprite = $"AnimatedSprite"

    if facing == "left":
        sprite.flip_h = true		
    else:
        sprite.flip_h = false


    match state:
        State.RUNNING:
            play_sound("walk", -20, 0.8)
        _:
            stop_sound("walk")

    match state:
        State.IDLE:
            sprite.animation = "idle"
        State.RUNNING:
            sprite.animation = "running"
        State.AIRBORNE:
            sprite.animation = "airborne"
        State.GRAPPLING:
            grapple_line.set_default_color(Color(0.0, 0.0, 0.0))
        State.REELING:
            grapple_line.set_default_color(Color(0.5, 0.5, 0.5))

    # update grapple visuals
    if state in [State.GRAPPLING, State.REELING, State.ATTACK]:
        grapple_line.visible = true
        if lastcoin != null:
            grapple_line.set_point_position(0, position)
            grapple_line.set_point_position(1, lastcoin.position)
    else:
        grapple_line.visible = false


func accelerate(delta, amount, speed_cap = 1000):
    # process acceleration

    if input_dir.x == 0:
        return false

    var acceleration = amount
    var in_lower_cap = false
    var in_upper_cap = false

    # check speed caps
    if velocity.x >= -speed_cap:
        in_lower_cap = true
    if velocity.x <= speed_cap:
        in_upper_cap = true

    # apply acceleration
    if in_lower_cap and input_dir.x < 0:
        velocity.x = max(-speed_cap, velocity.x - acceleration * abs(input_dir.x) * delta)
    if in_upper_cap and input_dir.x > 0:
        velocity.x = min(speed_cap, velocity.x + acceleration * abs(input_dir.x) * delta)

    return true

func set_grapple_line(from, to):
    grapple_line.set_point_position(0, from)
    grapple_line.set_point_position(1, to)

func attack(direction):

    var ATTACK_TIME = 0.2
    var TOTAL_TIME = 0.4
    var ATTACK_LENGTH = 80
    
    if state_time == 0:
        attack_dir = direction.normalized()

    if state_time <= ATTACK_TIME:
        velocity.y = 0

    grapple_line.visible = true
    grapple_line.set_default_color(Color(1.0, 1.0, 1.0))
    var endpoint = lerp(position, position + (attack_dir * ATTACK_LENGTH), pow(clamp(state_time / ATTACK_TIME, 0.0, 1.0), 2))
    set_grapple_line(position, endpoint)
        
    if state_time >= TOTAL_TIME:
        reset_state()

func _physics_process(delta):

    process_input(delta)

    var input_vector = Vector2(0, 0)
    input_vector.x = Input.get_action_strength("key_right") - Input.get_action_strength("key_left")
    input_vector.y = Input.get_action_strength("key_down") - Input.get_action_strength("key_up")
    # input_vector = input_vector.normalized()
    input_dir = input_vector

    var right = input_vector.x

    var skip_gravity = false


    if is_on_floor():
        dodges_left = 1;
        airjumps_left = 1;

        if num_coins() >= 1:
            coins_left = MAX_COINS;

    # shoot coin
    if Input.is_action_just_pressed("shoot"):

        if is_on_floor() or coins_left == MAX_COINS:
            coins_left = MAX_COINS
            clear_coins()

        if coins_left > 0:

            var coin = coin_scene.instance()
            lastcoin = coin
            add_child(coin)
            coin.set_as_toplevel(true)
            coin.position = position

            match coins_left:
                3:
                    coin.set_color(Color(0.8, 0.8, 0.3))
                2:
                    coin.set_color(Color(0.9, 0.2, 0.8))
                1:
                    coin.set_color(Color(0.9, 0.3, 0.3))

            if Input.get_action_strength("key_left"):
                coin.shoot_left()

            elif Input.get_action_strength("key_right"):
                coin.shoot_right()

            elif Input.get_action_strength("key_up"):
                coin.shoot_up()

            elif Input.get_action_strength("key_down"):
                coin.shoot_down()

            coins_left -= 1


    # position reset
    if Input.is_action_just_pressed("reset"):
        position = respawn_point

    # initiate dash
    if state in [State.IDLE, State.DASH] and (is_pressed("key_left", 0.1) or is_pressed("key_right", 0.1)):
        set_state(State.DASH)

    # intiate airdodge
    if state in [State.GRAPPLING, State.REELING, State.AIRBORNE] and dodges_left > 0 and input_vector != Vector2.ZERO and is_pressed("key_dodge", 0.2):
        grapple_line.visible = false
        dodges_left -= 1;
        dodge_direction = input_vector.normalized();
        set_state(State.DODGE)

    # grapple/attack
    if Input.is_action_just_pressed("grapple"):
        if lastcoin != null:  # grapple

            grapple_initial_vel = velocity
            grapple_dist = lastcoin.position.distance_to(position)
            set_state(State.GRAPPLING)
        elif not state in [State.ATTACK]:  # attack
            attack_dir = input_dir.normalized()
            set_state(State.ATTACK)

    # dropdown
    if state == State.IDLE and is_on_floor() and Input.is_action_just_pressed("key_down"):
        var collision = $"CollisionPolygon2D"
        if !test_move(Transform2D(0, position + Vector2(0, 8)), Vector2(0, 1)):
            collision.disabled = true
            var timer = Timer.new()
            add_child(timer)
            timer.connect("timeout", self, "_on_Timer_timeout")
            timer.one_shot = true
            timer.start(0.2)

    match state:
        State.ATTACK:
            attack(input_dir)

    if state == State.IDLE:

        if is_on_floor():
            if !accelerate(delta, ACCELERATION / 2.0, MAX_SPEED * abs(input_dir.x)):
                process_friction(delta)
        else:
            set_state(State.AIRBORNE)

    if state == State.DASH:

        if state_time == 0:

            if right > 0:
                play_sound("walk", -20, 0.8, true)
                play_particle_effect(dash_effect_scene, {"direction": Vector2(-3, -1)})
                velocity.x = MAX_SPEED * abs(input_dir.x)
            elif right < 0:
                play_sound("walk", -20, 0.8, true)
                play_particle_effect(dash_effect_scene, {"direction": Vector2(3, -1)})
                velocity.x = -MAX_SPEED * abs(input_dir.x)

        if state_time >= 0.05:
            set_state(State.RUNNING)


    if state == State.DODGE:

        var dodge_length = DODGE_LENGTH

        if state_time >= 0 and state_time < dodge_length:
            var dodge_speed = max(DODGE_SPEED, velocity.length())
            if facing == "left":
                airdash_effect.material.set_shader_param("flip", true)
            else:
                airdash_effect.material.set_shader_param("flip", false)
            airdash_effect.emitting = true
            velocity = dodge_direction * lerp(dodge_speed, 0, pow(state_time / dodge_length, 2))

        if state_time >= dodge_length or is_on_floor():
            airdash_effect.emitting = false
            reset_state()
    
    if state == State.RUNNING:

        if is_on_floor():

            if right == 0:
                set_state(State.IDLE)

            else:
                accelerate(delta, ACCELERATION, MAX_SPEED)
        else:
            set_state(State.AIRBORNE)

    if state == State.AIRBORNE:

        if is_on_floor():
            # player landed
            play_sound("land", -20)
            if right != 0:
                set_state(State.RUNNING)
            else:
                set_state(State.IDLE)

        else:
            accelerate(delta, AIR_ACCELERATION, MAX_SPEED)

    if state == State.GRAPPLING:

        var space_state = get_world_2d().direct_space_state
        var pivot = lastcoin.position

        var trace = space_state.intersect_ray(position, pivot, [self, lastcoin], 0b0001)

        if lastcoin != null and !trace:
            # update grapple visuals
            grapple_line.visible = true
            grapple_line.set_default_color(Color(0.0, 0.0, 0.0))
            grapple_line.set_point_position(0, position)
            grapple_line.set_point_position(1, pivot)

            # v1 physics
            # velocity = lerp(velocity, dir * 300, pow(min(1, state_time * (1 / 0.5)), elasticity))

            # allow swinging
            accelerate(delta, 500)

        # reel in
        if !Input.get_action_strength("grapple"):
        # if Input.is_action_just_pressed("key_jump"):
            set_state(State.REELING)

        # cancel grapple
        if Input.is_action_just_pressed("key_jump") or trace or lastcoin == null:
        # if !Input.get_action_strength("grapple") or trace or lastcoin == null:
            release_grapple()

    if state == State.REELING:

        var pivot = lastcoin.position
        var dir = position.direction_to(pivot)
        velocity = lerp(velocity, dir * 800, pow(min(1, state_time * (1 / 0.5)), 1))

        if state_time >= 0.5 or pivot.distance_to(position) < 48 or Input.is_action_just_pressed("key_jump"):
        # if state_time >= 0.5 or pivot.distance_to(position) < 48:
            release_grapple()

    # gravity
    if self.is_on_floor():
        velocity.y = 1

    elif state != State.DODGE and !skip_gravity:
        velocity.y = min(TERMINAL_VELOCITY, velocity.y + (GRAVITY * delta))
        if Input.is_action_just_pressed("key_down") and velocity.y > 0 and velocity.y < GRAVITY:
            velocity.y = GRAVITY

    # jumping
    if Input.is_action_just_pressed("key_jump"):
        jump()


    move(delta)

    # grapple swinging physics
    if state == State.GRAPPLING:

        var pivot = lastcoin.position
        var dist = position.distance_to(pivot)

        if dist >= grapple_dist:  # only applies if at max grapple length

            var new_pos = pivot + (pivot.direction_to(position) * grapple_dist)

            var old_dir = velocity.normalized()
            var new_dir = (new_pos - lastpos).normalized()

            var angle = old_dir.angle_to(new_dir)
            print("sin: %.2f, cos: %.2f" % [sin(angle), cos(angle)])

            position = new_pos
            var new_velocity = (position - lastpos).normalized() * velocity.length()
            velocity = new_velocity
            if abs(velocity.x) < 100:
                velocity.x *= abs(cos(angle))
            velocity.y *= abs(sin(angle)) 

    state_time += delta
    lastpos = position

func _on_Timer_timeout():
    $"CollisionPolygon2D".disabled = false

func release_grapple():
    # run at the end of a grapple or reel
    grapple_line.visible = false
    lastcoin.set_color(lastcoin.get_color().darkened(0.5))
    lastcoin = null
    velocity = velocity.normalized() * min(800, velocity.length())  # cap speed out of grapple
    reset_state()

func jump():

    if airjumps_left > 0:
        play_particle_effect(jump_scene)
        play_sound("jump", -10, 1, true)
        airjumps_left -= 1
        velocity.y = -JUMP_VELOCITY

    if is_on_floor():
        position.y -= 4
    else:
        if input_dir.x > 0:
            velocity.x = MAX_SPEED
        elif input_dir.x < 0:
            velocity.x = -MAX_SPEED

func dodge_state(delta):
    velocity = dodge_vector * DODGE_SPEED
    move(delta)

func move(delta):
    velocity = velocity.floor()
    velocity = move_and_slide(velocity, Vector2(0, -1), true)
    # velocity = move_and_slide_with_snap(velocity, Vector2(0, 1), Vector2(0, -1), true)
    debug_info.text = "speed: %3.2f (x=%3.2f, y=%3.2f)\nstate: %s" % [velocity.length(), velocity.x, velocity.y, State.keys()[state]]
