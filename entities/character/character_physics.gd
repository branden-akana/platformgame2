class_name CharacterPhysics extends Resource

@export_group("Movement Physics")

@export_subgroup("Grounded Movement")
@export var GROUND_ACCELERATION = 8000
@export var GROUND_FRICTION = 2000
@export var GROUND_MAX_SPEED = 600

@export var WALK_MAX_SPEED = 500

@export var FLOOR_SNAP_TOP_MARGIN = 4

@export_subgroup("Air Movement")
@export var AIR_ACCELERATION = 3000
@export var AIR_FRICTION = 2000
@export var AIR_MAX_SPEED = 600

# airdash

@export_subgroup("Airdash Behavior")
@export var AIRDASH_SPEED     = 1000  # (mininum) speed at start of airdash
@export var AIRDASH_SPEED_END = 200  # speed at end of airdash
@export var AIRDASH_LENGTH    = 12
@export var AIRDASH_CURVE    = 2.5
@export var AIRDASH_WAVELAND_MARGIN = 10

# jumping / gravity

@export_subgroup("Jump Behavior")
@export var JUMPSQUAT_LENGTH = 4  # amount of frames to stay grounded before jumping

@export var JUMP_VELOCITY = 800
@export var DASHJUMP_VELOCITY = 1000

@export_subgroup("Gravity")
@export var GRAVITY = 2000
@export var TERMINAL_VELOCITY = 600  # maximum downwards velocity
@export var FAST_FALL_SPEED = 1000

# dash

# captain falcon: 16 @ 60FPS
@export_subgroup("Dash Behavior")
@export var DASH_LENGTH = 16  # in frames
@export var DASH_SENSITIVITY = 0.3  # how fast you need to tilt the stick to start a dash (0 = more sensitive)

@export var DASH_STOP_SPEED = 400  # dash early stop speed

@export var DASH_INIT_SPEED = 500  # dash initial speed

@export var DASH_ACCELERATION = 20000  # dash acceleration
@export var DASH_ACCELERATION_REV = 12000  # dash reverse acceleration

@export var DASH_MAX_SPEED = 1200  # dash max speed
@export var DASH_MAX_SPEED_REV = 1400 # dash reverse max speed (moonwalking)

@export_subgroup("Run Behavior")
@export var RUNNING_STOP_SPEED: int = 1000

# buffers (frame window to accept these actions before they are actionable)

@export_subgroup("Input Buffers", "BUFFER_")
@export var BUFFER_JUMP = 4
@export var BUFFER_AIRDASH = 1

