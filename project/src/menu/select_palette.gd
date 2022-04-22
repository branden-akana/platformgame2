class_name SelectPalette
extends MenuSelection

func get_label():
    var current_palette = Game.get_post_processor().current_palette + 1
    var num_palettes = len(Game.get_post_processor().palettes)

    return "palette: %s/%s" % [current_palette, num_palettes]

func on_right(menu):
    menu.b_rotate_palettes = false
    var pp = Game.get_post_processor()
    var next_palette = (pp.current_palette + 1) % len(pp.palettes)
    pp.change_palette(next_palette)

func on_left(menu):
    menu.b_rotate_palettes = false
    var pp = Game.get_post_processor()
    var prev_palette = (pp.current_palette - 1 + len(pp.palettes)) % len(pp.palettes)
    pp.change_palette(prev_palette)
    