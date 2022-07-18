class_name SelectPalette
extends MenuSelection

func get_label(): return "color palette"

func get_extra():
    var current_palette = Game.get_display_manager().current_palette + 1
    var num_palettes = len(Game.get_display_manager().palettes)

    return "%s/%s" % [current_palette, num_palettes]

func on_hover(menu):
    menu.get_node("sample").visible = true
    menu.get_node("sample_2").visible = true

func on_unhover(menu):
    menu.get_node("sample").visible = false
    menu.get_node("sample_2").visible = false

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
    