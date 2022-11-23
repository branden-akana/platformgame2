class_name Player extends Character

# the currently recording replay
var replay = null

# frames where a signal should be sent
var signal_frames = {}

var ghost = null

@onready var flash_tween

func _ready():
	super._ready()

	connect("enemy_hit", self.on_enemy_hit)
	connect("enemy_killed", self.on_enemy_killed)


func on_action(action: String) -> void:
	super.on_action(action)

	match action:
		"attack":
			Sound.play("attack", -20, 0.7, false, true)
		"dash":
			Sound.play("dash", -20, 0.8, false, true)
		"jump":
			FXEmitter.play(FXEmitter.Jump, self)
			Sound.play("jump", -10, 1, false)
		"walljump_left":
			FXEmitter.play(FXEmitter.WallJumpRight, self)
			Sound.play("land", -20, 0.8 - 0.05 * consecutive_walljumps)
		"walljump_right":
			FXEmitter.play(FXEmitter.WallJumpLeft, self)
			Sound.play("land", -20, 0.8 - 0.05 * consecutive_walljumps)
		"land":
			FXEmitter.play(FXEmitter.Land, self)
			Sound.play("land", -20, 0.8)
		"airdash_restored":
			play_flash_effect()
		"drag":
			FXEmitter.play(FXEmitter.Dust, self)

# Start an effect where the player flashes
func play_flash_effect():
	if flash_tween:
		flash_tween.kill()
	
	self._model.color = Color(10.0, 10.0, 10.0)

	flash_tween = create_tween()
	flash_tween.tween_property(self._model, "color",
		Color(1.0, 1.0, 1.0), 0.2)

func on_airdash():
	if flash_tween:
		flash_tween.stop()

func on_enemy_hit(_enemy, contacts):
	signal_frames[tick] = "hit"

	Sound.play("hit", -10)
	# _gamestate.get_camera().screen_shake(1.0, 0.2)

	if not no_effects and len(contacts):
		# var effect = FXEmitter.play_anim(FXEmitter.HitEffect)
		var effect = FXEmitter.play(FXEmitter.HitEffect, self)
		effect.top_level = true
		effect.position = contacts[0]

func on_enemy_killed(_enemy, _contacts):
	pass
	# var effect = FXEmitter.play(FXEmitter.HitParticles)
	# effect.position = enemy.position
	# effect.direction = position.direction_to(enemy.position)

func pre_process(_delta):

	# update player color
	match airdashes_left:
		2:
			_model.color = Color(1.0, 1.0, 1.0)
		1:
			_model.color = Color(1.0, 1.0, 1.0)
			# sprite.modulate = Color(0.5, 0.5, 0.5)
		0:
			_model.color = Color(0.5, 0.5, 0.5)

	# needed as sometimes the walking sound does not stop
	if fsm.is_current(CharStateName.RUNNING):
		Sound.stop("walk")

	if _gamestate.is_paused() or _gamestate.is_in_menu:
		return

	if Input.is_action_just_pressed("reset"):
		player_restart()
		return

	# camera panning
	# if is_on_floor():
	#     var camera_offset = Vector2(0, 0)
	#     var down_held_time = buffer.get_time_held("key_down")
	#     var up_held_time = buffer.get_time_held("key_up")

	#     if down_held_time and buffer.get_action_strength("key_down") > 0.9:  # pan down
	#         # print("down held: %0.2f" % down_held_time)
	#         camera_offset = lerp(
	#             Vector2(0, 0), Vector2(0, 80),
	#             ease(clamp((down_held_time - 1.0) / 0.5, 0.0, 1.0), -2.8)
	#         )
	#     elif up_held_time and buffer.get_action_strength("key_up") > 0.9:  # pan up
	#         # print("up held: %0.2f" % up_held_time)
	#         camera_offset = lerp(
	#             Vector2(0, 0), Vector2(0, -80),
	#             ease(clamp((up_held_time - 1.0) / 0.5, 0.0, 1.0), -2.8)
	#         )

	#     _gamestate.get_camera().set_offset(camera_offset)

	# process player input
	for key in ["key_up", "key_down", "key_left", "key_right", "jump", "dodge", "attack", "special"]:
		var value = Input.get_action_strength(key)
		input.update_action(key, value)

	# record this tick into the replay
	if replay and _gamestate.run_timer.is_recording_enabled():
		replay.record_tick(self, tick)

# Do an animated restart
func player_restart():
	_gamestate.call_with_fade_transition(self, "restart")

##
## Player-specific implementation of hurt().
## Anything that hurts the player will play a fade-out-fade-in animation and respawn the player.
##
func hurt(damage = 100, respawn_point = null):
	await _gamestate.pause_and_fade_out(0.2)
	super.hurt(damage, respawn_point)
	await _gamestate.fade_in_and_unpause(0.2)
	# _gamestate.call_with_fade_transition(self, "hurt", [damage, respawn_point])

func respawn(pos):
	super.respawn(pos)
	if pos == _gamestate.get_start_point():
		_gamestate.restart_level()
	else:
		_gamestate.get_current_level().reset_current_room()
