class_name RunnerStateType

enum {
    IDLE, DASH, RUNNING, AIRBORNE, AIRDASH, JUMPSQUAT,
    SHOOTCOIN, GRAPPLE, REELING
    ATT_FORWARD, ATT_DAIR, ATT_UAIR,
    SPECIAL,
}

static func get_name(state) -> String:
    match state:
        IDLE:
            return "idle"
        DASH:
            return "dash"
        RUNNING:
            return "running"
        AIRBORNE:
            return "airborne"
        AIRDASH:
            return "airdash"
        JUMPSQUAT:
            return "jumpsquat"
        ATT_FORWARD:
            return "att_forward"
        ATT_DAIR:
            return "att_dair"
        ATT_UAIR:
            return "att_uair"
        SPECIAL:
            return "special"
        SHOOTCOIN:
            return "shootcoin"
        GRAPPLE:
            return "grapple"
        REELING:
            return "reeling"
    
    return "unknown"