class_name GameTimer

signal run_started
signal run_complete

var game
var replay_manager: ReplayManager

# seconds elapsed for the current level until completion
var time: float = 0.0

# the best completion time
var time_best: float = INF

var b_run_started: bool = false
var b_run_complete: bool = false
var b_recording_enabled: bool = true
var b_playback_enabled: bool = true

# various stats during a run

# number of times the player has died during the run
var num_deaths = 0

func _init(game):
    self.game = game
    self.replay_manager = ReplayManager.new(game)

func is_best_time():
    return b_run_complete and time <= time_best

func is_recording_enabled():
    return b_recording_enabled

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
        if b_recording_enabled:
            # create a new ghost replay
            replay_manager.save_recording()

    emit_signal("run_complete")

# Reset the ingame timer
func reset_run():
    print("[timer] run reset")
    time = 0.0
    num_deaths = 0
    b_run_complete = false
    HUD.set_best_time(time_best)
    if b_recording_enabled:
        replay_manager.stop_recording()
    if b_playback_enabled:
        replay_manager.stop_playback()


func start_run():
    print("[timer] run started")
    b_run_started = true
    if b_recording_enabled:
        replay_manager.start_recording()
    if b_playback_enabled:
        replay_manager.start_playback()
    emit_signal("run_started")


func clear_best_times():
    time_best = INF
    HUD.reset_best_time()
    replay_manager.clear_playback()


func on_player_death():
    if not b_run_complete:
        num_deaths += 1
