extends SceneTree
## Rasteriza icon.svg nos tamanhos exigidos pelo launcher Android.
##   godot --headless -s tools/make_icons.gd


func _init() -> void:
	var svg := FileAccess.open("res://icon.svg", FileAccess.READ).get_as_text()

	var principal := Image.new()
	principal.load_svg_from_string(svg, 192.0 / 128.0)
	principal.save_png("res://assets/icons/icon_192.png")

	# Adaptativo: primeiro plano com margem de segurança (66% centrais)
	var fg_base := Image.new()
	fg_base.load_svg_from_string(svg, 288.0 / 128.0)
	var fg := Image.create(432, 432, false, Image.FORMAT_RGBA8)
	fg.blit_rect(fg_base, Rect2i(0, 0, 288, 288), Vector2i(72, 72))
	fg.save_png("res://assets/icons/icon_adaptive_fg.png")

	var bg := Image.create(432, 432, false, Image.FORMAT_RGBA8)
	bg.fill(Color("1a1440"))
	bg.save_png("res://assets/icons/icon_adaptive_bg.png")

	print("ícones gerados em assets/icons/")
	quit(0)
