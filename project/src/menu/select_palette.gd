class_name SelectPalette
extends MenuSelection

func get_label():
    var current_palette = Game.get_display_manager().current_palette + 1
    var num_palettes = len(Game.get_display_manager().palettes)

    return "palette: %s/%s" % [current_palette, num_palettes]

func on_right(menu):
    menu.b_rotate_palettes = false
    var pp = Game.get_display_manager()
    var next_palette = (pp.current_palette + 1) % len(pp.palettes)
    pp.change_palette(next_palette, 0.2)

func on_left(menu):
    menu.b_rotate_palettes = false
    var pp = Game.get_display_manager()
    var prev_palette = (pp.current_palette - 1 + len(pp.palettes)) % len(pp.palettes)
    pp.change_palette(prev_palette, 0.2)
    