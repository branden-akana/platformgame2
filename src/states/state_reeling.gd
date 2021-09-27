extends RunnerState
class_name ReelingState

func on_update(delta):

    var coin = runner.lastcoin

    if coin:
        var pivot = coin.position
        var dir = runner.position.direction_to(pivot)
        runner.velocity = lerp(runner.velocity, dir * 800, pow(min(1, time * (1 / 0.5)), 1))

        if time >= 0.5 or pivot.distance_to(runner.position) < 30 or buffer.is_action_just_pressed("key_jump"):
        # if state_time >= 0.5 or pivot.distance_to(position) < 48:
            runner.release_grapple()
            reset_state()
