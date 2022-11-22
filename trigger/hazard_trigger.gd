#================================================================================
# HazardTrigger
#
# A 2D area that triggers hurting the character.
# If the character dies while in the trigger, respawn at a set location.
#
# The respawn location will be taken from a child Node2D named 'respawn'.
#================================================================================

@tool
class_name HazardTrigger extends LevelTrigger


@export var damage: int = 100

func _ready():
	_debug_color = Color.RED

##
## Gets the respawn point to send players after they die to this hazard.
## If no respawn point exists, the player will respawn at the start point.
##
func get_respawn_point() -> Vector2:
	if get_node_or_null("respawn"):
		return $"respawn".global_position
	elif not Engine.is_editor_hint():
		return GameState.get_start_point()
	else:
		return Vector2.ZERO
	
func set_size(new_size):
	size = new_size
	if ready:
		$collision.position = size / 2.0
		$collision.shape.extents = size / 2.0
		queue_redraw()

func _process(_delta):
	if Engine.is_editor_hint():
		queue_redraw()
	

func _draw():
	super._draw()
	if get_node_or_null("respawn"):
		# draw a line from the collision box to the respawn point
		var respawn_point = to_local(get_respawn_point())
		draw_arc(respawn_point, 8, 0, 2 * PI, 20, _debug_color, 2) 
		draw_line(_real_size() / 2, respawn_point, _debug_color, 2)
