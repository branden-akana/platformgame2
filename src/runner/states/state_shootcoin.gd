extends RunnerState
class_name ShootCoinState

const Coin = preload("res://scenes/Coin.tscn")

func on_update(delta):

    if runner.is_on_floor() or runner.coins_left == runner.MAX_COINS:

        runner.coins_left = runner.MAX_COINS
        runner.clear_coins()

    if runner.coins_left > 0:

        var coin: Coin = Coin.instance()
        coin.set_as_toplevel(true)
        coin.position = runner.position

        runner.lastcoin = coin
        runner.add_child(coin)

        # different colors depending on number of coins thrown
        match runner.coins_left:
            3:
                coin.set_color(Color(0.8, 0.8, 0.3))
            2:
                coin.set_color(Color(0.9, 0.2, 0.8))
            1:
                coin.set_color(Color(0.9, 0.3, 0.3))

        # determine throw direction
        if input.get_action_strength("key_up") >= 0.5:
            coin.shoot_up()

        elif input.get_action_strength("key_down") >= 0.5:
            coin.shoot_down()

        elif input.get_action_strength("key_left") >= 0.5:
            coin.shoot_left()

        elif input.get_action_strength("key_right") >= 0.5:
            coin.shoot_right()


        runner.coins_left -= 1

        goto_idle_or_dash()
