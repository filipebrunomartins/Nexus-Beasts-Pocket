class_name ScreenBase
extends Control
## Base das telas de menu: fundo, cabeçalho com voltar e helpers de UI.

const CENA_HOME := "res://game/home/home.tscn"

var conteudo: VBoxContainer


func montar_base(titulo: String, com_voltar: bool = true) -> void:
	var bg := ColorRect.new()
	bg.color = Color("14102b")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var raiz := MarginContainer.new()
	raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	for m in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		raiz.add_theme_constant_override(m, 20)
	add_child(raiz)

	conteudo = VBoxContainer.new()
	conteudo.add_theme_constant_override("separation", 14)
	raiz.add_child(conteudo)

	var topo := HBoxContainer.new()
	conteudo.add_child(topo)
	if com_voltar:
		var voltar := Button.new()
		voltar.text = "‹ Voltar"
		voltar.add_theme_font_size_override("font_size", 28)
		voltar.pressed.connect(func(): get_tree().change_scene_to_file(CENA_HOME))
		topo.add_child(voltar)
	var lbl := Label.new()
	lbl.text = titulo
	lbl.add_theme_font_size_override("font_size", 44)
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	topo.add_child(lbl)
	if com_voltar:
		var espaco := Control.new()
		espaco.custom_minimum_size = Vector2(140, 0)
		topo.add_child(espaco)


func label(texto: String, tamanho: int = 26, cor: Color = Color.WHITE) -> Label:
	var l := Label.new()
	l.text = texto
	l.add_theme_font_size_override("font_size", tamanho)
	l.add_theme_color_override("font_color", cor)
	return l


func botao(texto: String, ao_apertar: Callable, tamanho: int = 30) -> Button:
	var b := Button.new()
	b.text = texto
	b.add_theme_font_size_override("font_size", tamanho)
	b.pressed.connect(ao_apertar)
	return b


func zoom_carta(db: CardDB, card_id: String) -> void:
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.75)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.gui_input.connect(func(ev):
		if ev is InputEventMouseButton and ev.pressed:
			overlay.queue_free())
	add_child(overlay)
	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	centro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(centro)
	var carta := CardRenderer.nova(db, card_id)
	carta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	centro.add_child(carta)
