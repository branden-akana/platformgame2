extends Runner

# the currently recording replay
var replay = null

# frames where a signal should be sent
var signal_frames = {}

var ghost = null

onready var flash_tween = Util.new_tween(self)

func _ready():
    # connect signal to sound effects
    connect("walking", Sound, "play", ["walk", -20, 0.8, true, false])
    connect("stop_walking", Sound, "stop", ["walk"])
    connect("jump", Sound, "play", ["jump", -10, 1, false])
    connect("land", Sound, "play", ["land", -20, 0.9])
    connect("dash", Sound, "play", ["dash", -20, 0.8, false, true])
    connect("attack", Sound, "play", ["attack", -20, 0.7, false, true])

    # connect signals to particle effects
    # connect("jump", Effects, "play", [Effects.Jump, self, {"direction": -velocity}]) 
    connect("jump", Effects, "play", [Effects.Jump, self]) 
    connect("dragging", Effects, "play", [Effects.Dust, self])
    connect("land", Effects, "play", [Effects.Land, self]) 
    connect("walljump_left", Effects, "play", [Effects.WallJumpRight, self]) 
    connect("walljump_right", Effects, "play", [Effects.WallJumpLeft, self]) 

    connect("airdash", self, "on_airdash")
    connect("airdash_restored", self, "on_airdash_restored")
    connect("walljump_left", Sound, "play", ["land", -20, 0.8])
    connect("walljump_right", Sound, "play", ["land", -20, 0.8])
    # connect("walljump_left", self, "play_flash_effect")
    # connect("walljump_right", self, "play_flash_effect")

    connect("enemy_hit", self, "on_enemy_hit")
    connect("enemy_killed", self, "on_enemy_killed")

# Start an effect where the player flashes
func play_flash_effect():
    flash_tween.interpolate_property($sprite, "modulate:g", 10.0, 1.0, 0.2)
    flash_tween.start()

func on_airdash_restored():
    play_flash_effect()

func on_airdash():
    if flash_tween:
        flash_tween.reset_all()

func on_enemy_hit(enemy, contacts):
    signal_frames[tick] = "hit"

    Sound.play("hit", -10)
    Game.get_camera().screen_shake(1.0, 0.2)

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
    if fsm.current_state is RunningState:
        Sound.stop("walk")

    if Game.game_paused or Game.is_in_menu:
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

    #     Game.get_camera().set_offset(camera_offset)

    # process player input
    for key in ["key_up", "key_down", "key_left", "key_right", "key_jump", "key_dodge", "grapple", "shoot", "special"]:
        var value = Input.get_action_strength(key)
        input.update_action(key, value)

    # record this tick into the replay
    if Game.is_recording:
        replay.record_tick(self, tick)

# Do an animated restart
func player_restart():
    Game.call_with_fade_transition(self, "restart")

func hurt(damage = 100, respawn_point = null):
    Game.call_with_fade_transition(self, "_hurt", [damage, respawn_point])
    # .hurt(damage, respawn_point)

func respawn(pos):
    .respawn(pos)
    if pos == Game.get_start_point():
        Game.restart_level()
    else:
        Game.restart_room()
