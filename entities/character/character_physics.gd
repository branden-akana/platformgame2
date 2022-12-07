class_name CharacterPhysics extends Resource

@export_group("Movement Physics")

@export_subgroup("Grounded Movement")
@export var GROUND_ACCELERATION = 3000
@export var GROUND_FRICTION = 1400
@export var GROUND_MAX_SPEED = 400

@export var WALK_MAX_SPEED = 150

@export var FLOOR_SNAP_TOP_MARGIN = 4

@export_subgroup("Dash Behavior")
# captain falcon: 16 @ 60FPS
@export var DASH_LENGTH = 16  # in frames
@export var DASH_SENSITIVITY = 0.1  # how fast you need to tilt the stick to start a dash (0 = more sensitive)

@export var DASH_STOP_SPEED = 100  # dash early stop speed

@export var DASH_INIT_SPEED = 100  # dash initial speed

@export var DASH_ACCELERATION = 4000  # dash acceleration
@export var DASH_ACCELERATION_REV = 4000  # dash reverse acceleration

@export var DASH_MAX_SPEED = 400  # dash max speed
@export var DASH_MAX_SPEED_REV = 400 # dash reverse max speed (moonwalking)

@export_subgroup("Run Behavior")
@export var RUNNING_STOP_SPEED: int = 300

@export_subgroup("Air Movement")
@export var AIR_ACCELERATION = 1500
@export var AIR_FRICTION = 800
@export var AIR_MAX_SPEED = 400

# airdash

@export_subgroup("Airdash Behavior")
@export var AIRDASH_SPEED     = 800  # (mininum) speed at start of airdash
@export var AIRDASH_SPEED_END = 300   # speed at end of airdash
@export var AIRDASH_SPEED_CANCEL_AIR = 400  ## max air speed when airdash is canceled
@export var AIRDASH_SPEED_CANCEL_GND = 600  ## max ground speed when airdash ended early
@export var AIRDASH_LENGTH    = 8
@export var AIRDASH_CURVE    = 2.5
@export var AIRDASH_WAVELAND_MARGIN = 8

# jumping / gravity

@export_subgroup("Jump Behavior")
@export var JUMPSQUAT_LENGTH = 4  # amount of frames to stay grounded before jumping

@export var JUMP_VELOCITY = 425
@export var DASHJUMP_VELOCITY = 350

@export_subgroup("Gravity")
@export var GRAVITY = 1500
@export var GRAVITY_DAMP_RAMP = 150.0  # when y-velocity is below this value, start dampening gravity
@export var GRAVITY_MIN = 0.45 # the minimum amount of gravity to apply when gravity is dampened
@export var TERMINAL_VELOCITY = 400  # maximum downwards velocity
@export var FAST_FALL_SPEED = 500


# buffers (frame window to accept these actions before they are actionable)

@export_subgroup("Input Buffers", "BUFFER_")
@export var BUFFER_JUMP = 4
@export var BUFFER_AIRDASH = 1

