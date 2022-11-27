##================================================================================
## Character
##
## The base entity that is used by the player.
##================================================================================

class_name Character extends CharacterBody2D

# fired for actions performed directly caused by player input (jumping, attacking, etc.)
signal action_performed

# fired for actions performed outside of player input (landing, dragging, etc.)
signal action_occured

signal enemy_hit     # called when player hit an enemy
signal enemy_killed  # called when player killed an enemy

signal died
signal respawned

signal stun_start
signal stun_end


@export var _phys: CharacterPhysics = CharacterPhysics.new()

# state machine
@onready @export var fsm: CharStateMachine = CharStateMachine.new(self)

@onready var input: CharacterInput = CharacterInput.new(self)

@onready var _model: CharacterModel = $model

@onready var _ecb: CharECB = $ecb

# when active, "stun" the player (skip all physics processing)
@onready var stun_timer = Timer.new()

# when active, ignore gravity
@onready var air_stall_timer = Timer.new()


# flags
# ======================================================

# current physics tick. restarting sets this back to 0.
var tick: int = 0

var interpolated_position: Vector2 = position

# if false, then vertical movement should be processed
var is_grounded: bool = true :
	set(grounded):
		_set_grounded(grounded)
		is_grounded = grounded

## if true, then gravity should be applied
var b_gravity_enabled = false

## if false, player will not slide during movement calculations
var b_can_slide = true

## when the player becomes airborne, contains their y position
var airborne_height: float = 0.0

## current player facing direction
var facing: int = Direction.RIGHT

## if true, attacks don't do any damage
var no_damage = false

## if true, don't play certain effects
var no_effects = false

## if true, character can hit dead enemies
var ignore_enemy_hp = false

# number of jumps allowed to perform until the character touches the floor
# var jumps_left = 1

## number of dashes allowed to perform until the character touches the floor
var airdashes_left = 1

## number of walljumps performed before landing
var consecutive_walljumps = 0

## the time (in ticks) when the player last left the ground
var time_left_ground = 0

## INFO: The current GameState instance (set by GameState)
var _gamestate


func _ready():

	stun_timer.name = "stun_timer"
	stun_timer.one_shot = true
	add_child(stun_timer)

	air_stall_timer.name = "air_stall_timer"
	air_stall_timer.one_shot = true
	add_child(air_stall_timer)

	# $sprite.set_as_top_level(true)
	# _model.top_level = true

	$moveset.visible = true

	# state machine setup
	action_performed.connect(on_action)
	action_occured.connect(on_action)

	# event setup
	($hurtbox as Area2D).body_entered.connect(on_hurtbox_entered)
	($hurtbox as Area2D).area_entered.connect(on_hurtbox_entered)

	# animation player setup
	var ap: AnimationPlayer = _model._anim
	ap.set_blend_time("running", "idle", 0.1)
	ap.set_blend_time("attack_f", "idle", 0.1)
	ap.set_blend_time("jumpsquat", "jump", 0.2)


func _process(_delta):

	# _model.position = position.snapped(Vector2(4, 4))
	var delt = 1.0 / Engine.get_physics_frames()
	var frac = Engine.get_physics_interpolation_fraction()
	interpolated_position = lerp(global_position, global_position + (velocity * delt), frac)

	match facing:
		Direction.RIGHT:
			_model.flipped = false
		Direction.LEFT:
			_model.flipped = true
		
	if fsm.is_current(CharStateName.AIRBORNE) and _model.anim_get_current_animation() != "jump":
		_model.anim_play("airborne", true)


##
## Called before the character's physics is processed.
##
func pre_process(_delta):
	pass

##
## Process character input and movement physics.
##
func _physics_process(delta):  # update input and physics

	# print("char process: %s, %s" % [tick, 1.0 / delta])

	# pause check
	if _gamestate.is_paused(): return

	# skip processing if stunned
	if stun_timer.time_left > 0: return

	pre_process(delta)

	# restore dashes/jumps if grounded
	if is_grounded and not fsm.is_current(CharStateName.AIRDASH):
		restore_jumps()
		consecutive_walljumps = 0

	# update state
	fsm.process(delta)

	# apply gravity to velocity
	if b_gravity_enabled: apply_gravity(delta)

	# fix_incoming_collisions(delta, 40)

	# apply final movement
	move(delta)

	# snap to ground
	if is_grounded and not fsm.is_current(CharStateName.AIRBORNE) and not fsm.is_current(CharStateName.AIRDASH):
		var down_snap := Vector2.DOWN * 10.0
		if move_and_collide(down_snap, true): move_and_collide(down_snap)

	check_grounded()

	# read inputs
	input.update()

	tick += 1

#--------------------------------------------------------------------------------
# Getters / Setters
#--------------------------------------------------------------------------------

##
## Consume one of the player's airdash/jump charges. Cannot be lower than 0.
##
func consume_jump():
	airdashes_left = max(0, airdashes_left - 1)

##
## Restore all of the player's airdash/jump charges.
##
func restore_jumps():
	if airdashes_left != 1:
		action_occured.emit("airdash_restored")
	airdashes_left = 1;
	# jumps_left = 1;

# func set_ignore_platforms(ignore_platforms: bool) -> void:
#     b_ignore_platforms = ignore_platforms

#     set_collision_mask_value(9, !ignore_platforms)
#     _ecb.get_left().set_collision_mask_value(9, !ignore_platforms)
#     _ecb.get_right().set_collision_mask_value(9, !ignore_platforms)
#     _ecb.get_top().set_collision_mask_value(9, !ignore_platforms)
#     _ecb.get_bottom().set_collision_mask_value(9, !ignore_platforms)

func _set_grounded(grounded: bool, emit = true) -> void:
	if not is_grounded and grounded and emit:
		var fall_height = position.y - airborne_height
		# print("fall height: %s" % fall_height)
		if fall_height > 128:
			action_performed.emit("land")

	elif is_grounded and not grounded:
		time_left_ground = tick


func check_grounded():
	var floor_check = _ecb.bottom_collide_out()
	# var floor_check = _test_collide_down()
	# var floor_check = is_on_floor()

	if floor_check and velocity.y >= 0 and not is_grounded:
		is_grounded = true
		velocity.y = 0
	elif not floor_check and is_grounded:
		is_grounded = false


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

# Respawn the player at the start point of the level.
func restart():
	respawn(_gamestate.get_start_point())

# Respawn the player at a set position.
func respawn(pos):
	if pos == _gamestate.get_start_point():
		Util.cprint("[player] restarted")
		tick = 0
		input.reset()
	# print("[character] setting pos to %s" % pos)
	position = pos
	velocity = Vector2(0, 0)
	action_neutral()
	emit_signal("respawned")


# Stun the character for a specified amount of time.
func stun(frames):

	# convert frames to seconds
	var time = frames / float(Engine.physics_ticks_per_second)
	stun_timer.start(time)

	emit_signal("stun_start")
	_model.anim_stop(false)

	await stun_timer.timeout

	emit_signal("stun_end")
	_model.anim_play()


#================================================================================
# UPDATE LOOP (UPDATE VISUALS)
#================================================================================


func on_action(action: String) -> void:
	# print("action performed: %s" % action)
	match action:
		"jump", "walljump_left", "walljump_right":
			_model.anim_play("jump", false, true)
		"idle":
			_model.anim_play("idle")
		"dash":
			_model.anim_play("dash", false, true)
		"running":
			_model.anim_play("running")
		"jumpsquat":
			_model.anim_play("jumpsquat")


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

func move(_delta):

	var last_position := position
	var last_velocity := velocity

	move_and_slide()

	# check all slide collisions for unwanted collisions with platforms
	for i in range(get_slide_collision_count()):

		# retrieve data of the colliding tile
		var collision: KinematicCollision2D = get_slide_collision(i)
		var tile_map := (collision.get_collider() as TileMap)
		var test_position := collision.get_position() - collision.get_normal()
		var tile_data = tile_map.get_cell_tile_data(0, tile_map.local_to_map(tile_map.to_local(test_position)))

		if (
			tile_data and 
			tile_data.get_custom_data("is_platform") and
			# not collision.get_normal().is_equal_approx(Vector2.UP)  # this check might conflict with ramped platforms
			collision.get_position().y <= position.y
		):
				# undo and redo movement while ignoring platforms
				# print("ignoring platforms")
				position = last_position
				velocity = last_velocity
				set_collision_mask_value(10, false)
				move_and_slide()
				set_collision_mask_value(10, true)
				break

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


##
## If the player's collision shape is inside another collision shape (e.g. the world),
## resolve the collision by moving the player up to the top of the collision shape.
##
func fix_incoming_collisions(delta: float, margin: float) -> void:

	var collision := move_and_collide(velocity * delta, true, true, true)
	if !collision: return

	var collider = collision.get_collider()
	if collider is TileMap:
		_align_to_tile((collider as TileMap), collision.get_position() + collision.get_remainder(), margin)


func fix_collisions(margin: float) -> void:

	var collision_point = Vector2.UP
	var collisions = Util.intersect_point(self, collision_point, [], 0b1000000001)

	# print(collisions)

	for collision in collisions:
		var collider = collision.get_collider()
		# print("is tilemap: %s" % collider is TileMap)
		# _fix_tilemap_collision(collider, position + collision_point, margin)
		_align_to_tile(collider, position + collision_point, margin)
	
	# var ray = get_ecb().get_bottom()
	# var collider = ray.get_collider()
	# var collision_point = ray.get_collision_point() + Vector2(0, -1)

##
## Move the player (y-axis only) to the top of a tile at a position.
##
## tilemap			The TileMap that the player is colliding with.
## pos				The position (in global coordinates) to check.
##					The player will snap to the tile at this position.
## margin   		If the distance the player would have to move is less than this margin, snap the player's position
## polygon_index 	the ID of a polygon the tile owns (applicable if a tile has multiple polygons, usually =0)
##
func _align_to_tile(tilemap: TileMap, pos: Vector2, margin: float, polygon_index: int = 0) -> void:

	# find the TileData of the tile at the given position
	var map_coords := tilemap.local_to_map(tilemap.to_local(pos))
	var tile_data: TileData = tilemap.get_cell_tile_data(0, map_coords)

	if not tile_data: return

	# find the collision polygon points at layer 0
	var collision_polygon_points := tile_data.get_collision_polygon_points(0, polygon_index)

	if len(collision_polygon_points) == 0: return

	# func to find the point with the highest y-value
	var min_y = func(points: PackedVector2Array) -> Vector2:
		var mn: Vector2 = points[0]
		for pt in points: if pt.y < mn.y: mn = pt
		return mn

	var top = tilemap.map_to_local(map_coords) + min_y.call(collision_polygon_points)
	var diff = position.y - top.y
	# print("%d -> %d (%d)" % [position.y, top.y, diff])

	if diff >= 1.0 and diff <= margin:
		print("aligned player to tile: moved %.2f" % diff)
		position.y = top.y - 0.25  # snap to top of shape
		# velocity.y = 0
		#print(position)


# Align the character to the top of a one-way platform if the distance
# the character would have to shift is within a set margin.
# func align_to_platform(delta, margin = _phys.AIRDASH_WAVELAND_MARGIN):

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
func align_to_floor(_delta, margin = _phys.FLOOR_SNAP_TOP_MARGIN):
	
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
	if not is_grounded:
		if velocity.y <= _phys.TERMINAL_VELOCITY:
			velocity.y = min(_phys.TERMINAL_VELOCITY, velocity.y + (_phys.GRAVITY * delta))

##
## Accelerate the character horizontally.
##
func _acceleration(delta: float, accel = null, max_speed = null) -> void:

	var axis_x: float = input.get_axis_x()

	if accel == null or max_speed == null:
		if is_grounded:
			accel = _phys.GROUND_ACCELERATION
			max_speed = _phys.GROUND_MAX_SPEED
		else:
			accel = _phys.AIR_ACCELERATION
			max_speed = _phys.AIR_MAX_SPEED

	if axis_x > 0.0 and velocity.x < max_speed:
		velocity.x = min(max_speed, velocity.x + (axis_x * accel * delta))
	elif axis_x < 0.0 and velocity.x > -max_speed:
		velocity.x = max(-max_speed, velocity.x + (axis_x * accel * delta))

##
## Apply friction to the character horizontally.
##
func _friction(delta: float):
	var friction = _phys.GROUND_FRICTION if is_grounded else _phys.AIR_FRICTION

	if is_grounded and abs(velocity.x) > 0:
		action_occured.emit("drag")

	velocity.x = move_toward(velocity.x, 0, friction * delta)


#--------------------------------------------------------------------------------
# Actions
#
# action_x() functions will perform x action if possible.
# Does not take into account any inputs the player has made
# to call an action. (See CharStateMachine.process() for input checks).
#--------------------------------------------------------------------------------

##
## Drop down through a platform (only one-way platforms).
##
func action_dropdown():

	# var space := get_world_2d().direct_space_state
	# var params = PhysicsPointQueryParameters2D.new()
	# params.position = Vector2(0, 1)
	# params.collision_mask = 0b0010  # platforms
	# var res = space.intersect_point(params)

	# check if the tile is a drop-down
	if is_grounded and len(Util.intersect_point(self, Vector2(0, 24))) == 0:
		# set_ignore_platforms(true)
		position.y += 4
		action_performed.emit("dropdown")
		action_airborne()
		# await get_tree().create_timer(0.5).timeout
		# set_ignore_platforms(false)

##
## Make the player airborne. Manually tries to unground the player.
## Will instantly on the next frame when called while player is on the floor.
##
func action_airborne() -> void:
	fsm.change(CharStateName.AIRBORNE)
	is_grounded = false
	airborne_height = position.y
	b_gravity_enabled = true
	action_performed.emit("airborne")

##
## If the player airborne and falling, instantly fall at the maximum speed.
##
func action_fastfall():
	if not is_grounded and velocity.y > 0:
		velocity.y = _phys.FAST_FALL_SPEED
		action_performed.emit("fastfall")

##
## Transition to the IDLE state, where the player is in an idle animation.
##
func action_neutral():
	if fsm.change(CharStateName.IDLE):
		action_performed.emit("idle")

##
## Start a dash. Direction depends checked the current input direction.
##
func action_dash(dir: int) -> void:
	facing = dir
	fsm.change(CharStateName.DASH)
	action_performed.emit("dash")

##
## Start running.
##
func action_run() -> void:
	fsm.change(CharStateName.RUNNING)
	action_performed.emit("running")

##
## Perform an airdash.
## Will be ignored if the player is not inputting a move direction.
##
func action_airdash() -> void:
	var axis = input.get_axis()
	if !axis.is_equal_approx(Vector2.ZERO) and airdashes_left > 0:
		fsm.change(CharStateName.AIRDASH)
		action_performed.emit("airdash")

##
## Perform a walljump in either direction.
## Will be ignored if the player is not next to a wall.
##
func action_walljump() -> bool:
	var success = false
	if GameState.settings.walljump_type == Constants.WalljumpType.JOYSTICK:
		if input.pressed_right():
			success = _walljump_right()
		elif input.pressed_left():
			success = _walljump_left()
	
	elif GameState.settings.walljump_type == Constants.WalljumpType.JUMP:
		if input.pressed_jump():
			success = _walljump_any()
		if success:
			input.eat_input("jump")

	if success:
		action_airborne()

	return success

## Perform a walljump to the left if possible.
func _walljump_left() -> bool:
	return _walljump(Direction.LEFT)

## Perform a walljump to the right if possible.
func _walljump_right() -> bool:
	return _walljump(Direction.RIGHT)

## Perform a walljump in either direction if possible.
func _walljump_any() -> bool:
	return _walljump()

## Perform a walljump in the specified direction if possible.
func _walljump(dir = null) -> bool:

	# print("attempting walljump")
	
	if dir == null:
		if _ecb.right_collide_out():
			dir = Direction.LEFT
		elif _ecb.left_collide_out():
			dir = Direction.RIGHT
		else:
			return false
			
	if (
		dir == Direction.LEFT and not _ecb.right_collide_out()
		or dir == Direction.RIGHT and not _ecb.left_collide_out()
	):
		return false

	var jump_mult = max(0.9 - (0.1 * consecutive_walljumps), 0.6)
	var x_speed  # horizontal speed of walljump
	var sig  # signal to emit

	if dir == Direction.RIGHT:
		x_speed = _phys.AIR_MAX_SPEED
		sig = "walljump_right"
	else:
		x_speed = -_phys.AIR_MAX_SPEED
		sig = "walljump_left"

	# perform walljump if rays collided
	_jump(jump_mult, x_speed)
	self.facing = dir
	consecutive_walljumps += 1
	action_performed.emit(sig)
	
	return true

##
## Perform a jump.
##
## If in any grounded state, sends the character to the JUMPSQUAT state.
## If in the AIRBORNE or JUMPSQUAT state, instantly perform the jump.
##
## Performing the jump will reduce the total amount of airdash/jump charges.
##
func action_jump(factor = 1.0):
	# if jumps_left > 0:
	if airdashes_left > 0:
		if (is_grounded and
			not fsm.is_current(CharStateName.JUMPSQUAT) and
			not fsm.is_current(CharStateName.AIRDASH)):
			fsm.change(CharStateName.JUMPSQUAT)
			action_performed.emit("jumpsquat")
		else:
			print("time after left ground: %s" % (tick - time_left_ground))
			if not is_grounded and tick - time_left_ground > 14:
				consume_jump()
			_jump(factor)
			fsm.change(CharStateName.AIRBORNE)
			action_performed.emit("jump")

## Make the character jump.
func _jump(factor = 1.0, vel_x = null):

	var axis = input.get_axis()

	# determine horizontal velocity
	if not is_grounded:
		# airborne jump direction switch
		if vel_x:
			velocity.x = vel_x
		elif axis.x > input.PRESS_THRESHOLD:
			velocity.x = _phys.AIR_MAX_SPEED
		elif axis.x < -input.PRESS_THRESHOLD:
			velocity.x = -_phys.AIR_MAX_SPEED
		elif axis.y < -input.PRESS_THRESHOLD:
			velocity.x = 0
	else:
		# grounded jump direction switch
		if velocity.x < 0 and axis.x > input.PRESS_THRESHOLD:
			velocity.x = _phys.AIR_MAX_SPEED
		elif velocity.x > 0 and axis.x < -input.PRESS_THRESHOLD:
			velocity.x = -_phys.AIR_MAX_SPEED

	# determine jump height
	if fsm.is_current(CharStateName.AIRDASH):
		velocity.y = min(velocity.y, -_phys.DASHJUMP_VELOCITY * factor)
	else:
		velocity.y = -_phys.JUMP_VELOCITY * factor


# Perform an attack.
#
# The attack that will be used will be different depending checked the
# character's current joystick direction.
func action_attack():

	# update facing direction
	set_facing_to_input()

	if is_grounded:
		# grounded attacks
		fsm.change(CharStateName.ATT_FORWARD)
	else:
		# airborne attacks
		if input.holding_up():
			fsm.change(CharStateName.ATT_UAIR)

		elif input.holding_down():
			fsm.change(CharStateName.ATT_DAIR)

		else:
			fsm.change(CharStateName.ATT_FORWARD)

	action_performed.emit("attack")


func action_special():
	fsm.goto_special()

##
## Hurt the player.
##
## If the player dies from being hurt, they will respawn at the specified
## respawn point, or the start point if one isn't provided.
func hurt(_damage = 100, respawn_point = null):
	# _hurt(damage, respawn_point)
	emit_signal("died")
	if respawn_point:
		respawn(respawn_point)
	else:
		respawn(_gamestate.get_start_point())


# func _hurt(damage, respawn_point):


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
