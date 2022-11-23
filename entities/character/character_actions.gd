extends Node

enum {
	AIRDASH,       # can airdash out of this state
	ATTACK,        # can attack out of this state
	SPECIAL,       # can special out of this state
	JUMP,

	DASH,          # can dash out of this state
	EDGE_CANCEL,   # if grounded, can move to the airborne state when leaving the ground
	AIR_CANCEL,    # can move to the airborne state when leaving the ground
	IDLE_CANCEL,   # can move to the idle state when not pressing any direction
	DROPDOWN,      # can dropdown one-way platforms (changes to airborne state)

	FASTFALL,      # can fastfall
	LAND,          # can move to any grounded (idle, dash, or running) state when touching the ground
	WALLJUMP       # can walljump out of this state
}