extends RunnerState
class_name RunningState


func on_update(delta, runner, fsm):

    allow_dash_out(runner)
    allow_jump_out(runner)
    allow_dropdown(runner)
    allow_idle_out(runner)
    allow_air_out(runner)

    if is_current_state(fsm):

        #snap_down_to_ground(delta, 16)
        #snap_up_to_ground(delta, 16)

        if runner.is_facing_forward():
            process_ground_acceleration(runner, delta)
        else:
            fsm.goto_idle()


func on_end(state_to, runner, fsm):
    if state_to == State.IDLE:
        runner.velocity.x = clamp(runner.velocity.x, -200, 200)
    # print("stopped running")
    runner.emit_signal("stop_walking")
