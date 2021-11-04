#===============================================================================
# Replay
#
# Contains data on a player's input every frame, their initial conditions,
# as well as their pos/vel per frame.
# 
#===============================================================================
class_name Replay

var initial_conditions
var input_frames
var pos_frames

# Create a new replay.
func init(initial_conditions_, input_frames_, pos_frames_):

    initial_conditions = initial_conditions_
    input_frames = input_frames_
    pos_frames = pos_frames_
