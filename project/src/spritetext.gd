extends SpriteTextRenderer
tool

export (String) var text = "" setget set_text

func set_text(text_):
    text = String(text_)
    update()

func _draw():
    draw_text(self, text)
    
