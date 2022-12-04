class_name TickTimer

signal timeout

var tick := 0
var tick_end: int
var is_running := false

func start(time: int) -> void:
	tick = 0
	tick_end = time
	is_running = true

func stop() -> void:
	is_running = false

func update() -> void:
	if is_running:
		tick += 1
		if tick > tick_end:
			timeout.emit()
			is_running = false