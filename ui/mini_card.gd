class_name MiniCard
extends PanelContainer
## Miniatura de carta para grades (coleção, editor de baralho).

signal tocada(card_id: String)

var card_id: String


static func nova(db: CardDB, id: String, qtd: int = -1, possuida: bool = true) -> MiniCard:
	var m := MiniCard.new()
	m.card_id = id
	m.custom_minimum_size = Vector2(196, 150)
	var card := db.get_card(id)
	var cor := Color("#546e7a")
	if card["categoria"] == "besta":
		cor = Color(db.get_type(card["tipo"])["cor"])
	elif card["categoria"] == "reliquia":
		cor = Color(db.get_type(card["reliquia"]["tipo"])["cor"])
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = cor.darkened(0.6) if possuida else Color("#1c1c28")
	estilo.border_color = cor if possuida else Color("#333344")
	for b in ["border_width_left", "border_width_right", "border_width_top", "border_width_bottom"]:
		estilo.set(b, 3)
	for c in ["corner_radius_top_left", "corner_radius_top_right", "corner_radius_bottom_left", "corner_radius_bottom_right"]:
		estilo.set(c, 10)
	for mg in ["content_margin_left", "content_margin_right", "content_margin_top", "content_margin_bottom"]:
		estilo.set(mg, 8)
	m.add_theme_stylebox_override("panel", estilo)

	var v := VBoxContainer.new()
	m.add_child(v)
	var nome := Label.new()
	nome.text = card["nome"] if possuida else "???"
	nome.add_theme_font_size_override("font_size", 20)
	nome.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nome.custom_minimum_size = Vector2(0, 56)
	v.add_child(nome)

	var sub := Label.new()
	sub.add_theme_font_size_override("font_size", 17)
	sub.add_theme_color_override("font_color", Color("#b0bec5"))
	var raridade := int(card.get("raridade", 1))
	var rar_txt := "★" if raridade >= 5 else "♦".repeat(raridade)
	if card["categoria"] == "besta":
		sub.text = "%s PS%d %s" % [db.get_type(card["tipo"])["simbolo"], card["ps"], rar_txt]
	else:
		sub.text = "%s %s" % [card["categoria"].capitalize(), rar_txt]
	v.add_child(sub)

	if qtd >= 0:
		var badge := Label.new()
		badge.text = "×%d" % qtd
		badge.add_theme_font_size_override("font_size", 20)
		badge.add_theme_color_override("font_color", Color("#ffe082") if qtd > 0 else Color("#555566"))
		v.add_child(badge)

	m.gui_input.connect(func(ev):
		if ev is InputEventMouseButton and ev.pressed:
			m.tocada.emit(m.card_id))
	return m
