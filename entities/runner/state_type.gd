class_name State

enum {
    IDLE, DASH, RUNNING, AIRBORNE, AIRDASH, JUMPSQUAT,
    ATTACK, SPECIAL,
    SHOOTCOIN, GRAPPLE, REELING
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
        ATTACK:
            return "attack"
        SPECIAL:
            return "special"
        SHOOTCOIN:
            return "shootcoin"
        GRAPPLE:
            return "grapple"
        REELING:
            return "reeling"
    
    return "unknown"