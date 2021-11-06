extends RunnerState
class_name GrappleState

var grapple_initial_vel: Vector2
var max_grapple_length: float
var coin

func on_update(delta):

    if time == 0:  # init

        coin = runner.lastcoin
        if !coin:
            goto_idle_or_dash()
            return

        grapple_initial_vel = runner.velocity
        max_grapple_length = coin.position.distance_to(runner.position)

    # attempt path trace between player and last coin
    var space_state = runner.get_world_2d().direct_space_state
    var pivot = coin.position
    var trace = space_state.intersect_ray(runner.position, pivot, [self, coin], 0b0001)

    if coin != null and !trace:  # path trace success

        # update grapple visuals
        runner.grapple_line.visible = true
        runner.grapple_line.set_default_color(Color(0.0, 0.0, 0.0))
        runner.grapple_line.set_point_position(0, runner.position)
        runner.grapple_line.set_point_position(1, pivot)

        # v1 physics
        # velocity = lerp(velocity, dir * 300, pow(min(1, state_time * (1 / 0.5)), elasticity))

        # allow swinging
        # var axis = buffer.get_action_axis()
        # runner.apply_acceleration(delta, 500)

    # reel in
    if !input.get_action_strength("grapple"):
    # if buffer.is_action_just_pressed("key_jump"):
        set_state("reeling")

    # jump out of grapple
    if input.is_action_just_pressed("key_jump") or trace or coin == null:
    # if !buffer.get_action_strength("grapple") or trace or coin == null:
        runner.release_grapple()
        goto_idle_or_dash()

    # grapple swinging physics
    var dist = runner.position.distance_to(pivot)

    if dist >= max_grapple_length:  # only applies if at edge of grapple length

        var new_pos = pivot + (pivot.direction_to(runner.position) * max_grapple_length)

        var old_dir = runner.velocity.normalized()
        var new_dir = (new_pos - runner.lastpos).normalized()

        var angle = old_dir.angle_to(new_dir)
        print("sin: %.2f, cos: %.2f" % [sin(angle), cos(angle)])

        runner.position = new_pos
        var new_velocity = (runner.position - runner.lastpos).normalized() * runner.velocity.length()
        runner.velocity = new_velocity
        if abs(runner.velocity.x) < 100:
            runner.velocity.x *= abs(cos(angle))
        runner.velocity.y *= abs(sin(angle)) 
