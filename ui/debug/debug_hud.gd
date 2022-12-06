extends Node2D

var fps_timer

var state_history = []
const MAX_STATES = 20

func _ready():
    
    fps_timer = Timer.new()
    fps_timer.one_shot = false
    add_child(fps_timer)
    fps_timer.start(1.0)
    
    fps_timer.connect("timeout",Callable(self,"update_fps"))

    await GameState.ready

    GameState.get_player().fsm.connect("state_changed",Callable(self,"on_state_changed"))
    
func update_fps():
    $fps.text = "%d fps" % Engine.get_frames_per_second()

func on_state_changed(state_to, _state_from):
    state_history.insert(0, state_to)
    if len(state_history) > MAX_STATES: state_history.pop_back()
    $state_display/current_state.text = state_history[0]
    $state_display/past_states.text = "\n".join(PackedStringArray(state_history.slice(1, len(state_history) - 1)))

func _physics_process(_delta):
    $tick.text = GameState.get_player().tick
    $pos_x.text = round(GameState.get_player().global_position.x)
    $pos_y.text = round(GameState.get_player().global_position.y)
    $vel_x.text = round(GameState.get_player().velocity.x)
    $vel_y.text = round(GameState.get_player().velocity.y)
    $grounded.text = "grounded: %s" % GameState.get_player().is_grounded

    var ecb = GameState.get_player().get_ecb()
    var checked = Color(1, 1, 1, 1.0)
    var unchecked = Color(1, 1, 1, 0.5)

    $ray_l.color = checked if ecb.left_collide_out() else unchecked
    $ray_r.color = checked if ecb.right_collide_out() else unchecked
    $ray_u.color = checked if ecb.top_collide_out() else unchecked
    $ray_d.color = checked if ecb.bottom_collide_out() else unchecked
    
    
