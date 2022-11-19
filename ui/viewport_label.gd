extends SubViewport
#tool

#export (String, MULTILINE) onready var text :
	# get:
	# 	return text # TODOConverter40 Copy here content of get_text
	# set(mod_value):
	# 	mod_value  # TODOConverter40 Copy here content of set_text

#export (int, 0, 3) onready var align :
	# get:
	# 	return align # TODOConverter40 Copy here content of get_align
	# set(mod_value):
	# 	mod_value  # TODOConverter40 Copy here content of set_align

func set_text(text: String) -> void:
    $panel/label.text = text
    
func get_text() -> String:
    return $panel/label.text
    
func set_align(align: int) -> void:
    $panel/label.align = align
    
func get_align() -> int:
    return $panel/label.align
