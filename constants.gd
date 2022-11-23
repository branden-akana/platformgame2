extends Node

##=========================================================
## Constants
##=========================================================

# Target display resolution.
# (the size of one in-game level screen)
const SCREEN_SIZE := Vector2i(640, 360)

# path to the player
const PATH_PLAYER := NodePath("/root/main/viewport/player")

# path to the HUD
const PATH_HUD := NodePath("/root/main/hud")

# path to the currently loaded level
const PATH_LEVEL := NodePath("/root/main/viewport/level")

# path to the vfx manager
const PATH_DISPLAYER := NodePath("/root/main/post_process")

# path to the active camera
const PATH_CAMERA := NodePath("/root/main/viewport/camera")


enum WalljumpType {
	JOYSTICK,  # input walljumps by inputting a direction away from the wall
	JUMP       # input walljumps by pressing the jump button
}
