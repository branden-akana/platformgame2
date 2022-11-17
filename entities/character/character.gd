class_name Character extends CharacterBody2D

signal action

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

@export var GROUND_ACCELERATION = 8000
@export var GROUND_FRICTION = 2000
@export var GROUND_MAX_SPEED = 1000

@export var AIR_ACCELERATION = 5000
@export var AIR_FRICTION = 1000
@export var AIR_MAX_SPEED = 1000

@export var WALK_MAX_SPEED = 500

@export var FLOOR_SNAP_TOP_MARGIN = 4

# airdash

@export var AIRDASH_SPEED     = 1400  # (mininum) speed at start of airdash
@export var AIRDASH_SPEED_END = 600  # speed at end of airdash
@export var AIRDASH_LENGTH    = 16
@export var AIRDASH_WAVELAND_MARGIN = 10

# jumping / gravity

@export var JUMPSQUAT_LENGTH = 4  # amount of frames to stay grounded before jumping

@export var JUMP_VELOCITY = 1300
@export var DASHJUMP_VELOCITY = 1000
@export var GRAVITY = 3500
@export var TERMINAL_VELOCITY = 1200  # maximum downwards velocity
@export var FAST_FALL_SPEED = 1200

# dash

# captain falcon: 16 @ 60FPS
@export var DASH_LENGTH = 16  # in frames
@export var DASH_SENSITIVITY = 0.3  # how fast you need to tilt the stick to start a dash (0 = more sensitive)

@export var DASH_STOP_SPEED = 400  # dash early stop speed

@export var DASH_INIT_SPEED = 500  # dash initial speed

@export var DASH_ACCELERATION = 20000  # dash acceleration
@export var DASH_ACCELERATION_REV = 12000  # dash reverse acceleration

@export var DASH_MAX_SPEED = 1200  # dash max speed
@export var DASH_MAX_SPEED_REV = 1400 # dash reverse max speed (moonwalking)

@export var RUNNING_STOP_SPEED: int = 1000

# buffers (frame window to accept these actions before they are actionable)

@export var BUFFER_JUMP = 4
@export var BUFFER_AIRDASH = 1

enum WalljumpType {
	JOYSTICK,  # input walljumps by inputting a direction away from the wall
	JUMP       # input walljumps by pressing the jump button
}

@export var WALLJUMP_TYPE: WalljumpType = WalljumpType.JOYSTICK


# states
# ===========================================

# state machine
var fsm = StateMachine.new()


# child nodes
# ===========================================

@onready var input: BufferedInput = BufferedInput.new()

@onready var model: CharacterModel  = $model
@onready var ap: AnimationPlayer = model._anim

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

# if false, player will not slide during movement calculations
var b_can_slide = true

# when the player becomes airborne, contains their y position
var airborne_height: float = 0.0

# current player facing direction
var facing: int = Direction.RIGHT

# if true, attacks don't do any damage
var no_damage = false

# if true, don't play certain effects
var no_effects = false

# if true, character can hit dead enemies
var ignore_enemy_hp = false

# number of jumps allowed to perform until the character touches the floor
# var jumps_left = 1

# number of dashes allowed to perform until the character touches the floor
var airdashes_left = 1

# number of walljumps performed before landing
var consecutive_walljumps = 0

# the time (in ticks) when the player last left the ground
var time_left_ground = 0


# state variables
# ======================================================
 
# move character by this vector every tick
#var velocity = Vector2.ZERO

func _ready():

	stun_timer.name = "stun_timer"
	stun_timer.one_shot = true
	add_child(stun_timer)

	air_stall_timer.name = "air_stall_timer"
	air_stall_timer.one_shot = true
	add_child(air_stall_timer)

	# $sprite.set_as_top_level(true)
	$model.set_as_top_level(true)

	$moveset.visible = true

	# state machine setup
	fsm.init(self)
	connect("action", on_action)
	fsm.connect("state_changed", on_state_change)

	# event setup
	$hurtbox.connect("body_entered",Callable(self,"on_hurtbox_entered"))

	# animation player setup
	ap.set_blend_time("running", "idle", 0.1)
	ap.set_blend_time("attack_f", "idle", 0.1)
	ap.set_blend_time("jumpsquat", "jump", 0.2)

# func _exit_tree():
	# $sprite.queue_free()

#--------------------------------------------------------------------------------
# Getters / Setters
#--------------------------------------------------------------------------------

func get_ecb() -> CollisionPolygon2D:
	return $ecb as CollisionPolygon2D


# func set_ignore_platforms(ignore_platforms: bool) -> void:
#     b_ignore_platforms = ignore_platforms

#     set_collision_mask_value(9, !ignore_platforms)
#     $ecb.get_left().set_collision_mask_value(9, !ignore_platforms)
#     $ecb.get_right().set_collision_mask_value(9, !ignore_platforms)
#     $ecb.get_top().set_collision_mask_value(9, !ignore_platforms)
#     $ecb.get_bottom().set_collision_mask_value(9, !ignore_platforms)

func set_grounded(is_grounded, emit = true):
	if not b_is_grounded and is_grounded and emit:
		var fall_height = position.y - airborne_height
		# print("fall height: %s" % fall_height)
		if fall_height > 24:
			emit_signal("action", "land")
	elif not is_grounded and b_is_grounded:
		time_left_ground = tick

	b_is_grounded = is_grounded


func is_grounded():
	return b_is_grounded


func check_grounded():
	var floor_check = $ecb.bottom_collide_out()
	# var floor_check = _test_collide_down()
	# var floor_check = is_on_floor()

	if floor_check and velocity.y >= 0 and not b_is_grounded:
		set_grounded(true)
		velocity.y = 0
	elif not floor_check and b_is_grounded:
		set_grounded(false)


# Check for ground collision by doing a test move_and_collide.
func _test_collide_down() -> bool:
	# set_collision_mask_value(9, !_check_invalid_platform_collisions(false))
	var collision = move_and_collide(Vector2.DOWN, true, true, true)
	# if collision != null: print("angle: %s" % collision.get_angle())
	return collision != null and collision.get_angle() <= PI / 4.0
			

# Get the current state this character is in.
func get_current_state():
	return fsm.current_state


# Update the character's facing direction based checked
# current input direction.
func set_facing_to_input():
	var x = input.get_axis().x
	if x > 0:
		facing = Direction.RIGHT
	elif x < 0:
		facing = Direction.LEFT


# Return true if the character is moving in the same direction
# they are facing.
func is_facing_forward():
	var x = input.get_axis().x
	return (
		x > 0 and facing == Direction.RIGHT or
		x < 0 and facing == Direction.LEFT
	)


# Get a direction vector corresponding to which way the character is facing.
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

func get_axis() -> Vector2:
	var axis = input.get_axis()

	if axis.x >= 0.5:
		axis.x = 1
	elif axis.x <= -0.5:
		axis.x = -1

	if axis.y >= 0.5:
		axis.y = 1
	elif axis.y <= -0.5:
		axis.y = -1

	return axis

# Read for a left input, but only if up or down are not pressed.
func pressed_left_thru_neutral():
	# return input._is_axis_just_pressed(Vector2.LEFT, Vector2.ZERO)
	return input.is_axis_just_pressed(
		"key_right", "key_left", ["key_up", "key_down"], 0, 0.0
	)

# Read for a right input, but only if up or down are not pressed.
func pressed_right_thru_neutral():
	# return input._is_axis_just_pressed(Vector2.RIGHT, Vector2.ZERO)
	return input.is_axis_just_pressed(
		"key_left", "key_right", ["key_up", "key_down"], 0, 0.0
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
	return input.is_action_just_pressed("jump", BUFFER_JUMP, 0.0, false)

func pressed_jump_raw():
	return input.is_action_just_pressed("jump")

func holding_jump():
	return input.is_action_pressed("jump")

func pressed_attack():
	return input.is_action_just_pressed("attack")

func pressed_special():
	return input.is_action_just_pressed("special")

func pressed_airdash():
	return input.is_action_just_pressed("dodge", BUFFER_AIRDASH)


# Respawn the player at the start point of the level.
func restart():
	respawn(GameState.get_start_point())

# Respawn the player at a set position.
func respawn(pos):
	if pos == GameState.get_start_point():
		Util.cprint("[player] restarted")
		tick = 0
		input.reset()
	# print("[character] setting pos to %s" % pos)
	position = pos
	velocity = Vector2(0, 0)
	fsm.goto_idle()
	emit_signal("respawned")


# Stun the character for a specified amount of time.
func stun(frames):

	# convert frames to seconds
	var time = frames / float(Engine.physics_ticks_per_second)
	stun_timer.start(time)

	emit_signal("stun_start")
	# $sprite.stop()
	ap.stop(false)

	await stun_timer.timeout

	emit_signal("stun_end")
	# $sprite.play()
	ap.play()


#================================================================================
# UPDATE LOOP (UPDATE VISUALS)
#================================================================================

# Set the color (modulate) of the character.
func set_color(color: Color) -> void:
	#$sprite.modulate = color
	# model.set_color(color)
	$model.color = color

func on_state_change(state_to: String, state_from: String) -> void:
	# print("state change: %s" % state_to)
	match state_to:
		"idle":
			play_animation("idle")
		"dash":
			play_animation("dash", false, true)
		"running":
			play_animation("running")
		"jumpsquat":
			play_animation("jumpsquat")

func on_action(action: String) -> void:
	match action:
		"jump", "walljump_left", "walljump_right":
			play_animation("jump", false, true)

func _process(_delta):

	$model.position = Util.gridsnap(position, 4, false)

	match facing:
		Direction.RIGHT:
			model.flipped = false
		Direction.LEFT:
			model.flipped = true
		
	if fsm.is_in_state(CharStateName.AIRBORNE) and ap.current_animation != "jump":
		play_animation("airborne", true)


#================================================================================
# PHYSICS LOOP
#================================================================================

func pre_process(delta):
	pass

func _physics_process(delta):  # update input and physics

	# print("char process: %s, %s" % [tick, 1.0 / delta])

	# pause check
	if GameState.is_paused(): return

	# skip processing if stunned
	if stun_timer.time_left > 0: return

	pre_process(delta)

	# restore dashes/jumps if grounded
	if is_grounded() and not fsm.is_in_state(CharStateName.AIRDASH):
		if airdashes_left != 1:
			emit_signal("airdash_restored")

		airdashes_left = 1;
		# jumps_left = 1;
		consecutive_walljumps = 0;

	# update state
	fsm.process(delta)

	# apply gravity to velocity
	if b_gravity_enabled: apply_gravity(delta)

	# fix_incoming_collisions(delta, 40)

	# apply final movement
	move(delta, velocity)

	input.update()

	tick += 1


#--------------------------------------------------------------------------------
# Animations
#--------------------------------------------------------------------------------

# Play an animation from the beginning.
func play_animation(anim, from_end = false, force = false):
	if ap.current_animation != anim or force:
		# 3D model
		var speed = 1.0  # playback speed
		var seek = 0.0   # seconds in anim to skip to

		if anim == "attack_f":
			seek = 0.5

		ap.play(anim, -1, speed, from_end)
		ap.seek(seek)


# Set the current animation without playing from beginning.
func set_animation(anim):
	# 3D model
	ap.current_animation = anim


# detect hitting a platform from a non-one-way angle
func _check_invalid_platform_collisions(use_slides: bool = true) -> bool:
	if use_slides:
		for i in range(get_slide_collision_count()):

			var collision = get_slide_collision(i)
			if (collision and collision.get_collider()
				and collision.get_collider().is_in_group("platform")
				and collision.get_normal() != Vector2(0, -1)):
				return true
	else:
		for dir in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
			var collision = move_and_collide(dir, true, true, true)
			if (collision and collision.get_collider()
				and collision.get_collider().is_in_group("platform")
				and collision.get_normal() != Vector2(0, -1)):

				return true

	return false

func move(delta, velocity):

	# detect hitting a platform from a non-one-way angle
	var invalid_platform_collisions = _check_invalid_platform_collisions()

	# temporarily disable collision with platforms
	set_collision_mask_value(9, !invalid_platform_collisions)

	# fix_incoming_collisions(delta, 32)

	# if b_ignore_platforms: set_collision_mask_value(9, false)

	# cancel x-velocity if moving into wall
	# if ($ecb.left_collide_out() and velocity.x < 0
	#     or $ecb.right_collide_out() and velocity.x > 0):
	#     velocity.x = 0

	#if result: print("%s: %s" % [result.collider, result.position])
	set_velocity(velocity)
	move_and_slide()
	# velocity

	# move and slide implementation
	var max_slides = 2
	if not is_grounded():
		max_slides = 5

	set_velocity(velocity)
	set_up_direction(Vector2.UP)
	set_floor_stop_on_slope_enabled(false)
	set_max_slides(max_slides)
	move_and_slide()

	# check and update grounded state
	if not invalid_platform_collisions:
		check_grounded()

	# if b_ignore_platforms: set_collision_mask_value(9, true)

	# for i in range(max_slides):

	#     result = move_and_collide(motion)

	#     if !b_can_slide or !result or result.remainder.is_equal_approx(Vector2()): break

	#     if i == 0:  # first slide
	#         var motion_slide_norm = result.remainder.slide(result.normal).normalized()
	#         motion = motion_slide_norm * (motion.length() - result.travel.length())
	#     else:
	#         motion = result.remainder.slide(result.normal)

	#     if motion.dot(velocity) <= 0.0 or motion.is_equal_approx(Vector2()): break


# Align the character to the top of a ledge they were about to collide with if
# the distance the character would have to shift is within a set margin.
# func align_to_ledge(delta):

#     var collision = $test_body_bot.move_and_collide(Vector2(velocity.x * delta, 0), true, true, true)
#     var top_collision = $test_body_top.move_and_collide(Vector2(velocity.x * delta, 0), true, true, true)
	
#     if collision and collision.normal != Vector2.UP and not top_collision:
#         var collider = collision.get_collider()
#         var shape_idx = collision.get_collider_shape_index()

#         var owner_idx = collider.shape_find_owner(shape_idx)
#         var tilemap = collider.shape_owner_get_owner(owner_idx)
#         #var shape = collider.shape_owner_get_shape(owner_idx, shape_idx)
		
#         var tilepos = tilemap.map_to_world(
#             tilemap.local_to_map(tilemap.to_local(collision.position))
#         )
		
#         # align y-axis to ledge if within margin
#         var margin = round(position.y - tilepos.y)
#         print("ledge margin = %s" % margin)
#         if position.y != tilepos.y and margin <= AIRDASH_WAVELAND_MARGIN:
#             position.y = tilepos.y
#             position.x += velocity.x * delta
#             print("snapped to y=%s" % tilepos.y)


# Attempt to retrieve the owner of the shape that was collided with.
func _collision_get_shape_owner(collider: CollisionObject2D, shape_index: int) -> Object:

	# get the shape ID
	# var shape_idx = collision.get_collider_shape_index()

	# get the ID of the shape's owner
	var owner_idx = collider.shape_find_owner(shape_index)
	# return the shape's owner
	return collider.shape_owner_get_owner(owner_idx)


# If the player's collision shape is inside another collision shape (e.g. the world),
# resolve the collision by moving the player up to the top of the collision shape.
func fix_incoming_collisions(delta: float, margin: float) -> void:

	var collision = move_and_collide(velocity * delta, true, true, true)

	if !collision: return

	# try to find if the collider is a TileMap

	var tilemap: TileMap

	if collision.get_collider() is CollisionObject2D:

		# try to retrieve the tilemap that was collided with
		var shape_idx = collision.get_collider_shape_index()
		tilemap = _collision_get_shape_owner(collision.collider, shape_idx)

	elif collision.get_collider() is TileMap:

		tilemap = collision.get_collider()

	_fix_tilemap_collision(tilemap, collision.get_position(), margin)


func fix_collisions(margin: float) -> void:

	var collision_point = Vector2.UP
	var collisions = Util.intersect_point(self, collision_point, [], 0b1000000001)

	# print(collisions)

	for collision in collisions:
		var collider = collision.get_collider()
		# print("is tilemap: %s" % collider is TileMap)
		_fix_tilemap_collision(collider, position + collision_point, margin)
	
	# var ray = get_ecb().get_bottom()
	# var collider = ray.get_collider()
	# var collision_point = ray.get_collision_point() + Vector2(0, -1)


func _fix_tilemap_collision(tilemap: TileMap, collision_point: Vector2, margin: float, shape_id: int = 0):

	if not tilemap is TileMap: return

	# try to retrieve the shape of the specific tile that was collided with
	var collider_shape = _get_tilemap_shape(tilemap, collision_point, shape_id)
	# print("shape: %s" % [collider_shape])

	if len(collider_shape) and position.y:
		var top_y = _min_y(collider_shape)  # y of top of shape
		var diff = position.y - top_y
		# print("%s -> %s (%s)" % [position.y, top_y, diff])
		if not is_equal_approx(position.y, top_y) and (diff > 0 and diff <= margin):
			print("fixed collision: shifted up from %s to %s" % [position.y, top_y])
			position.y = top_y  # snap to top of shape
			# velocity.y = 0
			#print(position)


# Attempt to retrieve the specific shape that was collided with,
# if the collider is a TileMap.
#
# If a shape cannot be found an empty array is returned.
func _get_tilemap_shape(tilemap, position: Vector2, layer: int = 0, polygon_index: int = 0) -> PackedVector2Array:

	# get the map coordinates, world coordinates, and id of the tile that was collided with
	var tile_coords: Vector2i = tilemap.local_to_map(tilemap.to_local(position))
	# print("tile_coords: %s" % tile_coords)
	var tile_pos: Vector2 = tilemap.map_to_local(tile_coords)
	var tile_id: int = tilemap.get_cell_source_id(layer, tile_coords)
	var tile_data: TileData = tilemap.get_cell_tile_data(layer, tile_coords)

	if tile_id == -1:
		print("tested tile_id is -1")
		return PackedVector2Array()

	# get the shape of the tile (first shape)
	var points := tile_data.get_collision_polygon_points(layer, polygon_index)

	return points


func _min_y(points: PackedVector2Array) -> float:
	var mn = INF
	for pt in points: if pt.y < mn: mn = pt.y
	return mn




# Align the character to the top of a one-way platform if the distance
# the character would have to shift is within a set margin.
# func align_to_platform(delta, margin = AIRDASH_WAVELAND_MARGIN):

#     # cast a ray from inside character down to try and detect a platform
#     var ray = Util.intersect_ray(self, Vector2(0, - margin), Vector2.DOWN * margin)

#     # only apply snap when character is moving perfectly horizontal
#     if velocity.y >= 0 and ray:
#         print("detected below floor")

#         # move character up then down to attempt snap to floor
#         move_and_collide(Vector2.UP * (margin + 1))
#         move_and_collide(Vector2.DOWN * (margin + 1))
#         return true

#     return false


# Align the character to the floor if the distance the character would have to
# shift is within a set margin.
func align_to_floor(delta, margin = FLOOR_SNAP_TOP_MARGIN):
	
	# cast a ray down below character to detect a floor
	var ray = Util.intersect_ray(self, Vector2(0, 0), Vector2.DOWN * margin)

	if ray:
		move_and_collide(Vector2.DOWN * (margin + 1))
		return true

	return false


# Stall the character (vertically) in the air for a certain number of frames.
func do_air_stall(frames = 18):
	velocity.y = 0
	b_gravity_enabled = false
	air_stall_timer.start(frames * get_physics_process_delta_time())

	await air_stall_timer.timeout
	b_gravity_enabled = true
	

func apply_gravity(delta):
	if not is_grounded():
		velocity.y = min(TERMINAL_VELOCITY, velocity.y + (GRAVITY * delta))
		# if input.is_action_just_pressed("key_down") and velocity.y > 0 and velocity.y < GRAVITY:
		# velocity.y = GRAVITY

func _acceleration(delta: float, dir = null) -> void:
	var accel
	var max_speed

	dir = get_axis() if dir == null else dir

	if is_grounded():
		accel = GROUND_ACCELERATION
		max_speed = GROUND_MAX_SPEED
	else:
		accel = AIR_ACCELERATION
		max_speed = AIR_MAX_SPEED

	if dir == Vector2.RIGHT and velocity.x < max_speed:
		velocity.x = min(max_speed, velocity.x + (dir.x * accel * delta))
	elif dir == Vector2.LEFT and velocity.x > -max_speed:
		velocity.x = max(-max_speed, velocity.x + (dir.x * accel * delta))


func _friction(delta: float):
	var friction = GROUND_FRICTION if is_grounded() else AIR_FRICTION

	if is_grounded() and abs(velocity.x) > 0:
		emit_signal("dragging")

	velocity.x = move_toward(velocity.x, 0, friction * delta)


# Apply acceleration to the character
# func apply_acceleration(delta, x, acceleration, max_speed):

#     var in_lower_cap = false
#     var in_upper_cap = false

#     # check speed caps
#     if velocity.x >= -max_speed:
#         in_lower_cap = true
#     if velocity.x <= max_speed:
#         in_upper_cap = true

#     # apply acceleration
#     if in_lower_cap and x < 0:
#         velocity.x = max(-max_speed, velocity.x - acceleration * abs(x) * delta)
#     if in_upper_cap and x > 0:
#         velocity.x = min(max_speed, velocity.x + acceleration * abs(x) * delta)

#     return true

# Apply friction (deceleration) to the character
# func apply_friction(delta, friction = FRICTION):
#     if is_grounded() and abs(velocity.x) > 0:
#         emit_signal("dragging")
#     velocity.x = move_toward(velocity.x, 0, friction * delta)

#--------------------------------------------------------------------------------
# Actions
#
# action_x() functions will perform x action if possible.
# Does not take into account any inputs the player has made
# to call an action. (See StateMachine.process() for input checks).
#--------------------------------------------------------------------------------

# Drop down through a platform (only one-way platforms).
# Will instantly send the character to the "airborne" state.
func action_dropdown():
	# check if the tile is a drop-down
	if is_grounded() and len(Util.intersect_point(self, Vector2(0, 24))) == 0:
		# set_ignore_platforms(true)
		position.y += 4
		fsm.goto_airborne()
		emit_signal("action", "dropdown")
		# await get_tree().create_timer(0.5).timeout
		# set_ignore_platforms(false)


# If airborne and falling, instantly fall at the maximum speed.
func action_fastfall():
	if not is_grounded() and velocity.y > 0:
		velocity.y = FAST_FALL_SPEED
		emit_signal("action", "fastfall")


func action_neutral():
	fsm.goto_idle()
	emit_signal("action", "idle")


# Initiate a dash. Direction depends checked the current input direction.
func action_dash():
	fsm.goto_dash() 
	emit_signal("action", "dash")


func action_airdash():
	var axis = get_axis()
	# if (
	#     not axis.is_equal_approx(Vector2.ZERO)
	#     and current_type == CharStateName.ATTACK
	#     and not character.is_grounded() or current_type != CharStateName.ATTACK
	#     and round(axis.length()) != 0
	# ):
	if !axis.is_equal_approx(Vector2.ZERO) and airdashes_left > 0:
		fsm.goto_airdash()


func action_walljump() -> bool:
	var success = false
	if WALLJUMP_TYPE == WalljumpType.JOYSTICK:
		if pressed_right():
			success = _walljump_right()
		elif pressed_left():
			success = _walljump_left()
	
	elif WALLJUMP_TYPE == WalljumpType.JUMP:
		if pressed_jump():
			success = _walljump_any()
		if success:
			input.eat_input("jump")

	if success:
		fsm.goto_airborne()

	return success

func _walljump_left() -> bool:
	return _walljump(Direction.LEFT)

func _walljump_right() -> bool:
	return _walljump(Direction.RIGHT)

# Perform a walljump in either direction if possible.
func _walljump_any() -> bool:
	return _walljump()

# Perform a walljump in the specified direction if possible.
func _walljump(dir = null) -> bool:

	# print("attempting walljump")
	
	if dir == null:
		if $ecb.right_collide_out():
			dir = Direction.LEFT
		elif $ecb.left_collide_out():
			dir = Direction.RIGHT
		else:
			return false
			
	if (
		dir == Direction.LEFT and not $ecb.right_collide_out()
		or dir == Direction.RIGHT and not $ecb.left_collide_out()
	):
		return false

	var jump_mult = max(0.9 - (0.1 * consecutive_walljumps), 0.6)
	var x_speed  # horizontal speed of walljump
	var sig  # signal to emit

	if dir == Direction.RIGHT:
		x_speed = AIR_MAX_SPEED
		sig = "walljump_right"
	else:
		x_speed = -AIR_MAX_SPEED
		sig = "walljump_left"

	# perform walljump if rays collided
	_jump(jump_mult, true, x_speed)
	self.facing = dir
	consecutive_walljumps += 1
	emit_signal("action", sig)
	
	return true


# Perform a jump.
# If grounded, sends the character to the "jumpsquat" state.
# If airborne, instantly perform the jump.
func action_jump(factor = 1.0):
	# if jumps_left > 0:
	if airdashes_left > 0:
		if (is_grounded() and
			not fsm.is_in_state([CharStateName.JUMPSQUAT, CharStateName.AIRDASH])):
			fsm.goto_jumpsquat()
			emit_signal("action", "jumpsquat")
		else:
			print("time after left ground: %s" % (tick - time_left_ground))
			if not is_grounded() and tick - time_left_ground > 14:
				airdashes_left -= 1
			_jump(factor)
			fsm.goto_airborne()
			emit_signal("action", "jump")

# Make the character jump. If force is true, ignore how many jumps they have left.
func _jump(factor = 1.0, force = false, vel_x = null):

	var axis = input.get_axis()

	# determine horizontal velocity
	if not is_grounded():
		# airborne jump direction switch
		if vel_x:
			velocity.x = vel_x
		elif axis.x > input.PRESS_THRESHOLD:
			velocity.x = AIR_MAX_SPEED
		elif axis.x < -input.PRESS_THRESHOLD:
			velocity.x = -AIR_MAX_SPEED
		elif axis.y < -input.PRESS_THRESHOLD:
			velocity.x = 0
	else:
		# grounded jump direction switch
		if axis.y < -input.PRESS_THRESHOLD:
			velocity.x = 0

	# determine jump height
	if fsm.is_in_state(CharStateName.AIRDASH):
		velocity.y = min(velocity.y, -DASHJUMP_VELOCITY * factor)
	else:
		velocity.y = -JUMP_VELOCITY * factor

# Perform an attack.
#
# The attack that will be used will be different depending checked the
# character's current joystick direction.
func action_attack():

	# update facing direction
	set_facing_to_input()

	if is_grounded():
		# grounded attacks
		fsm.set_state(CharStateName.ATT_FORWARD)
	else:
		# airborne attacks
		if holding_up():
			fsm.set_state(CharStateName.ATT_UAIR)

		elif holding_down():
			fsm.set_state(CharStateName.ATT_DAIR)

		else:
			fsm.set_state(CharStateName.ATT_FORWARD)

	emit_signal("action", "attack")


func action_special():
	fsm.goto_special()


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
		respawn(GameState.get_start_point())


# Called when a body intersects this character's hurtbox.
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
