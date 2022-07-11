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

signal stun_start
signal stun_end

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
export var AIRDASH_WAVELAND_MARGIN = 40

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


# states
# ===========================================

# state machine
var fsm = StateMachine.new()


# child nodes
# ===========================================

onready var input: BufferedInput = BufferedInput.new()

onready var model: Spatial = get_node("viewport_container/viewport/captain/falcon")
onready var ap: AnimationPlayer = get_node("viewport_container/viewport/captain/animation_player")

# when active, "stun" the player (skip all physics processing)
var stun_timer = Timer.new()

# when active, ignore gravity
var air_stall_timer = Timer.new()


# flags
# ======================================================

# current physics tick. restarting sets this back to 0.
var tick: int = 0

# if false, then vertical movement should be processed
var b_is_grounded = true

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


# state variables
# ======================================================
 
# move runner by this vector every tick
var velocity = Vector2.ZERO


func _ready():

    stun_timer.name = "stun_timer"
    stun_timer.one_shot = true
    add_child(stun_timer)

    air_stall_timer.name = "air_stall_timer"
    air_stall_timer.one_shot = true
    add_child(air_stall_timer)

    $sprite.set_as_toplevel(true)

    $moveset.visible = true

    # state machine setup
    fsm.init(self)

    # event setup
    $hurtbox.connect("body_entered", self, "on_hurtbox_entered")

    # animation player setup
    ap.set_blend_time("running", "idle", 0.1)
    ap.set_blend_time("attack_f", "idle", 0.1)
    ap.set_blend_time("jumpsquat", "jump", 0.2)

func _exit_tree():
    $sprite.queue_free()

#--------------------------------------------------------------------------------
# Getters / Setters
#--------------------------------------------------------------------------------

func set_grounded(is_grounded, emit = true):
    if not b_is_grounded and is_grounded and emit:
        emit_signal("land")
    b_is_grounded = is_grounded


func is_grounded():
    return b_is_grounded


func check_grounded():
    if is_on_floor() and not b_is_grounded:
        set_grounded(true)
    elif not is_on_floor() and b_is_grounded:
        set_grounded(false)

            
# Get the current state this runner is in.
func get_current_state():
    return fsm.current_state


# Update the runner's facing direction based on
# current input direction.
func set_facing_to_input():
    var x = input.get_axis().x
    if x > 0:
        facing = Direction.RIGHT
    elif x < 0:
        facing = Direction.LEFT


# Return true if the runner is moving in the same direction
# they are facing.
func is_facing_forward():
    var x = input.get_axis().x
    return (
        x > 0 and facing == Direction.RIGHT or
        x < 0 and facing == Direction.LEFT
    )


# Get a direction vector corresponding to which way the runner is facing.
func get_facing_dir() -> Vector2:
    if facing == Direction.RIGHT:
        return Vector2.RIGHT
    else:
        return Vector2.LEFT


func set_input_handler(input_):
    self.input = input_


#--------------------------------------------------------------------------------
# Input Checks
#--------------------------------------------------------------------------------

func pressed_down():
    return input.is_action_just_pressed("key_down")

func pressed_up():
    return input.is_action_just_pressed("key_up")

func pressed_left():
    return input.is_action_just_pressed("key_left")

func pressed_right():
    return input.is_action_just_pressed("key_right")

func holding_down():
    return input.is_action_pressed("key_down")

func holding_up():
    return input.is_action_pressed("key_up")

func holding_left():
    return input.is_action_pressed("key_left")

func holding_right():
    return input.is_action_pressed("key_right")

func get_axis():
    return input.get_axis()

# Read for a left input, but only if up or down are not pressed.
func pressed_left_thru_neutral():
    return input.is_axis_just_pressed(
        "key_right", "key_left", ["key_up", "key_down"], 0.0, 0.0
    )

# Read for a right input, but only if up or down are not pressed.
func pressed_right_thru_neutral():
    return input.is_axis_just_pressed(
        "key_left", "key_right", ["key_up", "key_down"], 0.0, 0.0
    )

# Return true if the left stick is in the neutral position.
func is_axis_neutral():
    var deadzone = 0.01
    return input.get_axis().length() <= deadzone

func is_axis_x_neutral():
    var deadzone = 0.01
    return abs(input.get_axis().x) <= deadzone

func get_axis_x():
    return input.get_axis().x

func pressed_jump():
    return input.is_action_just_pressed("key_jump", BUFFER_JUMP)

func holding_jump():
    return input.is_action_pressed("key_jump")

func pressed_attack():
    return input.is_action_just_pressed("grapple")

func pressed_special():
    return input.is_action_just_pressed("special")

func pressed_airdash():
    return input.is_action_just_pressed("key_dodge", BUFFER_AIRDASH)


# Respawn the player at the start point of the level.
func restart():
    respawn(Game.get_start_point())
    tick = 0


# Respawn the player at a set position.
func respawn(pos):
    # print("[runner] setting pos to %s" % pos)
    position = pos
    velocity = Vector2(0, 0)
    fsm.goto_idle()
    input.reset()
    emit_signal("respawned")


# Stun the runner for a specified amount of time.
func stun(frames):

    # convert frames to seconds
    var time = frames / float(Engine.iterations_per_second)
    stun_timer.start(time)

    emit_signal("stun_start")
    $sprite.stop()

    yield(stun_timer, "timeout")

    emit_signal("stun_end")
    $sprite.play()


#================================================================================
# UPDATE LOOP (UPDATE VISUALS)
#================================================================================

# Set the color (modulate) of the runner.
func set_color(color: Color) -> void:
    #$sprite.modulate = color
    model.get_node("Skeleton/body").material_override.albedo_color = color

func _process(_delta):

    if is_instance_valid(model):
        match facing:
            Direction.RIGHT:
                model.rotation_degrees.y = 0
            Direction.LEFT:
                model.rotation_degrees.y = 180
            
        if fsm.current_state is RunningState or fsm.current_state is DashState:    
            play_animation("running")
        elif fsm.current_state is IdleState:
            play_animation("idle")
        elif fsm.current_state is AirborneState and ap.current_animation != "jump":
            play_animation("airborne", true)

    # check player direction (for flipping sprites)
    match facing:
        Direction.RIGHT:
            $sprite.flip_h = false
        Direction.LEFT:
            $sprite.flip_h = true

    # update sprite animation
    if fsm.current_state is IdleState:
        $sprite.animation = "idle"
    elif fsm.current_state is DashState:
        $sprite.animation = "running"
    elif fsm.current_state is RunningState:
        $sprite.animation = "running"
    elif fsm.current_state is AirborneState:
        $sprite.animation = "airborne"

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
    $sprite.position = Util.gridsnap(global_position + Vector2(0, -64), 4, false)

#================================================================================
# PHYSICS LOOP
#================================================================================

func pre_process(delta):
    pass

func _physics_process(delta):  # update input and physics

    pre_process(delta)

    # pause check
    if Game.game_paused: return

    # skip processing if stunned
    if stun_timer.time_left > 0: return

    # restore dashes/jumps if grounded
    if b_is_grounded:
        if airdashes_left != 1:
            emit_signal("airdash_restored")

        airdashes_left = 1;
        jumps_left = 1;

    # update state
    fsm.current_state.process(delta, self, fsm)

    # apply gravity to velocity
    if b_gravity_enabled: apply_gravity(delta)

    # apply final movement
    velocity = move(delta, velocity)

    # check and update grounded state
    check_grounded()

    tick += 1


#--------------------------------------------------------------------------------
# Animations
#--------------------------------------------------------------------------------

# Play an animation from the beginning.
func play_animation(anim, from_end = false, force = false):
    if (
        is_instance_valid(model)
        and ap.has_animation(anim)
        and (ap.current_animation != anim or force)
    ):
        # 3D model
        var speed = 2.0  # playback speed
        var seek = 0.0   # seconds in anim to skip to

        if anim == "attack_f":
            speed = 1.5
            seek = 0.5

        ap.play(anim, -1, speed, from_end)
        ap.seek(seek)
    else:
        # 2D sprite
        $sprite.animation = anim
        $sprite.frame = 0

# Set the current animation without playing from beginning.
func set_animation(anim):
    if is_instance_valid(model) and ap.has_animation(anim):
        # 3D model
        ap.current_animation = anim
    else:
        # 2D sprite
        $sprite.animation = anim


# Restart the current animation.
func restart_animation():
    $sprite.frame = 0

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
    align_to_ledge(delta)

    position = position.round()
    return new_velocity


# Align the runner to the top of a ledge they were about to collide with if
# the distance the runner would have to shift is within a set margin.
func align_to_ledge(delta):

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


# Align the runner to the top of a one-way platform if the distance
# the runner would have to shift is within a set margin.
func align_to_platform(delta, margin = AIRDASH_WAVELAND_MARGIN):

    # cast a ray from inside runner down to try and detect a platform
    var ray = Util.intersect_ray(self, Vector2(0, - margin), Vector2.DOWN * margin)

    # only apply snap when runner is moving perfectly horizontal
    if velocity.y >= 0 and ray:
        print("detected below floor")

        # move runner up then down to attempt snap to floor
        move_and_collide(Vector2.UP * (margin + 1))
        move_and_collide(Vector2.DOWN * (margin + 1))
        return true

    return false


# Align the runner to the floor if the distance the runner would have to
# shift is within a set margin.
func align_to_floor(delta, margin = FLOOR_SNAP_TOP_MARGIN):
    
    # cast a ray down below runner to detect a floor
    var ray = Util.intersect_ray(self, Vector2(0, 0), Vector2.DOWN * margin)

    if ray:
        move_and_collide(Vector2.DOWN * (margin + 1))
        return true

    return false


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


#--------------------------------------------------------------------------------
# Actions
#--------------------------------------------------------------------------------

# Drop down through a platform (only one-way platforms).
# Will instantly send the runner to the "airborne" state.
func do_dropdown():
    # if is_on_floor():
    if b_is_grounded:
        # check if the tile is a drop-down
        if not Util.collide_point(self, position + Vector2(0, 96)):
            position += Vector2(0, 4)
            fsm.goto_airborne()


# Perform a jump.
# If grounded, sends the runner to the "jumpsquat" state.
# If airborne, instantly perform the jump.
func do_jump():
    if b_is_grounded:
        fsm.goto_jumpsquat()
    else:
        jump()


# Perform a walljump in either direction if possible.
func do_walljump():
    _walljump(Direction.RIGHT)
    _walljump(Direction.LEFT)


# If airborne and falling, instantly fall at the maximum speed.
func do_fastfall():
    if not b_is_grounded and velocity.y > 0:
        velocity.y = FAST_FALL_SPEED


# Initiate a dash. Direction depends on the current input direction.
func do_dash():
    fsm.goto_dash() 


# Perform a walljump in the specified direction if possible.
func _walljump(dir = Direction.RIGHT):

    var margin = 40
    var jump_mult = 0.8
    var top_offset = Vector2(0, -48)
    var bot_offset = Vector2(0, 0)

    var x_speed  # horizontal speed of walljump
    var cast  # ray cast direction
    var sig  # signal to emit

    if dir == Direction.RIGHT:
        x_speed = MAX_SPEED
        cast = Vector2.LEFT * margin
        sig = "walljump_right"
    else:
        x_speed = -MAX_SPEED
        cast = Vector2.RIGHT * margin
        sig = "walljump_left"

    # detect walls using raycasts
    var top_ray = Util.intersect_ray(self, top_offset, cast)
    var bot_ray = Util.intersect_ray(self, bot_offset, cast)

    # perform walljump if rays collided
    if top_ray and bot_ray:
        jump(jump_mult, true, x_speed)
        self.facing = dir
        emit_signal(sig)


# Make the runner jump. If force is true, ignore how many jumps they have left.
func jump(factor = 1.0, force = false, vel_x = null):

    var axis = input.get_axis()

    if jumps_left == 0 and not force: return

    # determine horizontal velocity

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

    # deplete total jumps

    # if airdashes_left > 0 or force:
    if not force:
    # if not force and not is_on_floor():
        jumps_left -= 1
        # airdashes_left -= 1
        
    # determine jump height

    if fsm.current_state is AirdashState:
        velocity.y = min(velocity.y, -DASHJUMP_VELOCITY * factor)
    else:
        velocity.y = -JUMP_VELOCITY * factor

    if not force: emit_signal("jump")

    # reset jump animation 
    play_animation("jump", false, true)
        
    fsm.goto_airborne()

# Perform an attack.
#
# The attack that will be used will be different depending on the
# runner's current joystick direction.
func do_attack():

    # update facing direction
    set_facing_to_input()

    # switch to attack state
    fsm.goto_attack()

    if is_grounded():
        # grounded attacks
        
        fsm.current_state.move = $"moveset/normal_forward"
    else:
        # airborne attacks

        if holding_up():
            fsm.current_state.move = $"moveset/normal_up"

        elif holding_down():
            fsm.current_state.move = $"moveset/normal_down"

        else:
            fsm.current_state.move = $"moveset/normal_forward"

    emit_signal("attack")



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

    # put player in stun
    stun(stun_frames)

    emit_signal("enemy_hit", enemy, contacts)

