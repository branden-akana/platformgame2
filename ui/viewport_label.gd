extends Viewport
#tool

#export (String, MULTILINE) onready var text setget set_text, get_text
#export (int, 0, 3) onready var align setget set_align, get_align

func set_text(text: String) -> void:
    $panel/label.text = text
    
func get_text() -> String:
    return $panel/label.text
    
func set_align(align: int) -> void:
    $panel/label.align = align
    
func get_align() -> int:
    return $panel/label.align
