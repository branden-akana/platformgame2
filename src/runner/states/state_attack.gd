extends RunnerState
class_name AttackState

const OFFSET: Vector2 = Vector2(120, -16)
var HitEffect = preload("res://scenes/particles/hit_effect.tscn")
var HitParticles = preload("res://scenes/particles/hit_particles.tscn")

var attack_f
var attack_u
var attack_d

var sprite  # ref to active attack sprite
var hitbox  # ref to active attack hitbox

# if true, this attack has hit an enemy
var hit_detected: bool = false

# if true, this attack was done on the ground
var is_grounded: bool = true

enum Attack {FORWARD, UP, DOWN}

var attack_type = 0

func on_init():
    
    attack_f = runner.get_node("attack_f")
    attack_u = runner.get_node("attack_u")
    attack_d = runner.get_node("attack_d")

    attack_f.connect("area_shape_entered", self, "on_area_enter")
    attack_u.connect("area_shape_entered", self, "on_area_enter")
    attack_d.connect("area_shape_entered", self, "on_area_enter")

func on_start(_state_name):

    var axis = buffer.get_action_axis()

    if axis.x > 0:
        runner.facing = Direction.RIGHT
    elif axis.x < 0:
        runner.facing = Direction.LEFT

    # detect attack direction

    # check which attack to use
    if round(axis.y) == -1: # aiming up
        sprite = attack_u.get_node("sprite")
        hitbox = attack_u.get_node("hitbox")
        attack_type = Attack.UP
    elif not runner.is_on_floor() and round(axis.y) == 1: # aiming down
        sprite = attack_d.get_node("sprite")
        hitbox = attack_d.get_node("hitbox")
        attack_type = Attack.DOWN
    else:
        sprite = attack_f.get_node("sprite")
        hitbox = attack_f.get_node("hitbox")
        attack_type = Attack.FORWARD

    # check which direction to face the attack
    match runner.facing:
        Direction.RIGHT:
            sprite.position = sprite.position.abs()
            hitbox.position = hitbox.position.abs()
            sprite.flip_h = false
        Direction.LEFT:
            sprite.position = sprite.position.abs() * Vector2(-1, 1)
            hitbox.position = hitbox.position.abs() * Vector2(-1, 1)
            sprite.flip_h = true

    if round(axis.y) == -1:  # flip y position when facing up
        sprite.position *= Vector2(1, -1)
        hitbox.position *= Vector2(1, -1)

    sprite.frame = 0
    sprite.playing = true
    runner.sprite.animation = "attack"
    runner.sprite.frame = 0

    hitbox.disabled = false
    hit_detected = false
    is_grounded = runner.is_on_floor()

    # runner.camera.screen_shake(16.0, 0.5)

func on_update(delta):

    # allow jump cancelling
    # if hit_detected:
        # check_jump()

    if not is_active():
        return

    if tick <= 5:
        hitbox.disabled = false
    else:
        hitbox.disabled = true

    if runner.is_on_floor():
        is_grounded = true
        process_friction(delta)
    else:
        check_fastfall()
        process_air_acceleration(delta)

    # keep applying gravity for uairs
    if (0.3 <= time and time <= 0.5) or not hit_detected or attack_type == Attack.UP:
        runner.apply_gravity(delta)

    # end of attack or edge cancelled
    if time >= 0.5 or (is_grounded and not runner.is_on_floor()):
        reset_state()

func get_shape(area, area_shape):
    return area.shape_owner_get_shape(area.shape_find_owner(area_shape), area_shape)

func on_area_enter(_area_id, area: Area2D, area_shape, _local_shape):
    if (
        area is Enemy
        and (area.health > 0 or runner.ignore_enemy_hp)
    ):
        # on hit behavior
        if attack_type != Attack.UP:
            runner.velocity.y = 0  # cancel vertical momentum
        runner.jumps_left = 1  # restore jump
        hit_detected = true
        runner.stun(0.1)

        # effects
        if not runner.no_effects:
            var shape = hitbox.shape
            var contacts = shape.collide_and_get_contacts(
                hitbox.global_transform,
                get_shape(area, area_shape),
                area.global_transform)

            if len(contacts):
                var effect = HitEffect.instance()    
                effect.position = (contacts[0] / 4).floor() * 4
                effect.frame = 0
                $"/root/main".add_child(effect)

        if not runner.no_damage:
            area.damage(runner)

            if area.health == 0:
                var effect = HitParticles.instance()
                effect.position = area.position
                effect.direction = runner.position.direction_to(area.position)
                effect.emitting = true
                $"/root/main".add_child(effect)

            Game.get_camera().screen_shake(1.0, 0.2)
            runner.emit_signal("hit")

func on_end():
    hitbox.disabled = true
    sprite.frame = 4  # hide sprite
