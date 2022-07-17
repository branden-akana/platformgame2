class_name GameTimer

signal run_started
signal run_complete

# seconds elapsed for the current level until completion
var time: float = 0.0

# the best completion time
var time_best: float = INF

var b_run_started: bool = false

var b_run_complete: bool = false

# various stats during a run

# number of times the player has died during the run
var num_deaths = 0

func is_best_time():
    return b_run_complete and time <= time_best

func process(delta):
    if b_run_started and not b_run_complete:
        if not Game.is_paused():
            time += delta

        if len(Game.get_enemies()) > 0 and len(Game.get_alive_enemies()) == 0:
            complete_run()

    HUD.set_timer(time)
    HUD.set_deaths(num_deaths)

# Called when the level is complete. Stops the timer.
func complete_run():
    print("[timer] run complete")
    b_run_complete = true
    b_run_started = false

    # calculate time difference
    HUD.set_diff_time(time, time_best)

    # check for new best time
    if is_best_time():
        print("[timer] new best time recorded")
        time_best = time
        HUD.set_best_time(time_best)
        # create a new ghost replay
        Game.replay_manager.save_recording()

    emit_signal("run_complete")

# Reset the ingame timer
func reset_run():
    print("[timer] run reset")
    time = 0.0
    num_deaths = 0
    HUD.set_best_time(time_best)

func start_run():
    print("[timer] run started")
    b_run_started = true
    emit_signal("run_started")

func clear_best_times():
    time_best = INF
    HUD.reset_best_time()

func on_player_death():
    if not b_run_complete:
        num_deaths += 1