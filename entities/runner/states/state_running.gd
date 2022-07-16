extends RunnerState
class_name RunningState


func on_update(delta, runner, fsm):
    if is_current_state(fsm):

        #snap_down_to_ground(delta, 16)
        #snap_up_to_ground(delta, 16)

        if runner.is_facing_forward():
            process_ground_acceleration(runner, delta)
        else:
            return RunnerStateType.IDLE


func on_end(state_to, runner, fsm):
    # if state_to == RunnerStateType.IDLE:
        # runner.velocity.x = clamp(runner.velocity.x, -runner.RUNNING_STOP_SPEED, runner.RUNNING_STOP_SPEED)
    # print("stopped running")
    runner.emit_signal("stop_walking")
