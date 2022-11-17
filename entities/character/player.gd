class_name Player extends Character

# the currently recording replay
var replay = null

# frames where a signal should be sent
var signal_frames = {}

var ghost = null

@onready var flash_tween

func _ready():

	super._ready()

	# connect signal to sound effects
	connect("walking",Callable(Sound,"play").bind("walk", -20, 0.8, true, false))
	connect("stop_walking",Callable(Sound,"stop").bind("walk"))
	connect("attack",Callable(Sound,"play").bind("attack", -20, 0.7, false, true))

	# connect signals to particle effects
	connect("jump",Callable(Effects,"play").bind(Effects.Jump, self, {"direction": -velocity})) 
	connect("jump",Callable(Effects,"play").bind(Effects.Jump, self)) 
	connect("dragging",Callable(Effects,"play").bind(Effects.Dust, self))

	# connect("airdash",Callable(self,"on_airdash"))
	connect("airdash_restored", self.on_airdash_restored)
	connect("walljump_left",Callable(self,"play_flash_effect"))
	connect("walljump_right",Callable(self,"play_flash_effect"))

	connect("enemy_hit", self.on_enemy_hit)
	connect("enemy_killed", self.on_enemy_killed)

func on_action(action: String) -> void:
	match action:
		"attack":
			Sound.play("attack", -20, 0.7, false, true)
		"dash":
			Sound.play("dash", -20, 0.8, false, true)
		"jump":
			Sound.play("jump", -10, 1, false)
		"walljump_left":
			Effects.play(Effects.WallJumpRight, self)
			Sound.play("land", -20, 0.8 - 0.05 * consecutive_walljumps)
		"walljump_right":
			Effects.play(Effects.WallJumpLeft, self)
			Sound.play("land", -20, 0.8 - 0.05 * consecutive_walljumps)
		"land":
			Effects.play(Effects.Land, self)
			Sound.play("land", -20, 0.8)

# Start an effect where the player flashes
func play_flash_effect():
	if flash_tween:
		flash_tween.kill()
	
	flash_tween = create_tween()
	flash_tween.tween_method(self.set_color,
		Color(10.0, 10.0, 10.0),
		Color(1.0, 1.0, 1.0), 0.2)

func on_airdash_restored():
	play_flash_effect()

func on_airdash():
	if flash_tween:
		flash_tween.stop()

func on_enemy_hit(enemy, contacts):
	signal_frames[tick] = "hit"

	Sound.play("hit", -10)
	GameState.get_camera().screen_shake(1.0, 0.2)

	if not no_effects and len(contacts):
		var effect = Effects.play_anim(Effects.HitEffect)
		effect.position = (contacts[0] / 4).floor() * 4
		effect.frame = 0

func on_enemy_killed(enemy, contacts):
	var effect = Effects.play(Effects.HitParticles)
	effect.position = enemy.position
	effect.direction = position.direction_to(enemy.position)

func pre_process(delta):

	# update player color
	match airdashes_left:
		2:
			set_color(Color(1.0, 1.0, 1.0))
		1:
			set_color(Color(1.0, 1.0, 1.0))
			# sprite.modulate = Color(0.5, 0.5, 0.5)
		0:
			set_color(Color(0.5, 0.5, 0.5))

	# needed as sometimes the walking sound does not stop
	if fsm.is_in_state(CharStateName.RUNNING):
		Sound.stop("walk")

	if GameState.is_paused() or GameState.is_in_menu:
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

	#     GameState.get_camera().set_offset(camera_offset)

	# process player input
	for key in ["key_up", "key_down", "key_left", "key_right", "jump", "dodge", "attack", "special"]:
		var value = Input.get_action_strength(key)
		input.update_action(key, value)

	# record this tick into the replay
	if replay and GameState.run_timer.is_recording_enabled():
		replay.record_tick(self, tick)

# Do an animated restart
func player_restart():
	GameState.call_with_fade_transition(self, "restart")

func hurt(damage = 100, respawn_point = null):
	GameState.call_with_fade_transition(self, "_hurt", [damage, respawn_point])
	# super.hurt(damage, respawn_point)

func respawn(pos):
	super.respawn(pos)
	if pos == GameState.get_start_point():
		GameState.restart_level()
	else:
		GameState.get_current_level().reset_current_room()
