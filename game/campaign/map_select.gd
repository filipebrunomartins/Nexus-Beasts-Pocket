extends ScreenBase
## Seleção de mapa da campanha: 4 mapas em dificuldade crescente.

var db: CardDB


func _ready() -> void:
	db = CardDB.load_default()
	montar_base("Campanha")
	var mapas := Campaign.carregar()

	var lista := VBoxContainer.new()
	lista.add_theme_constant_override("separation", 18)
	lista.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lista.alignment = BoxContainer.ALIGNMENT_CENTER
	conteudo.add_child(lista)

	for i in mapas.size():
		var mapa: Dictionary = mapas[i]
		var aberto := Campaign.mapa_desbloqueado(Save.dados, mapas, i)
		var painel := PanelContainer.new()
		painel.custom_minimum_size = Vector2(0, 190)
		var estilo := StyleBoxFlat.new()
		estilo.bg_color = Color("#26224a") if aberto else Color("#1a1830")
		estilo.border_color = Color("#7df9ff") if aberto else Color("#2a2845")
		for b in ["border_width_left", "border_width_right", "border_width_top", "border_width_bottom"]:
			estilo.set(b, 3)
		for c in ["corner_radius_top_left", "corner_radius_top_right", "corner_radius_bottom_left", "corner_radius_bottom_right"]:
			estilo.set(c, 16)
		for m in ["content_margin_left", "content_margin_right", "content_margin_top", "content_margin_bottom"]:
			estilo.set(m, 18)
		painel.add_theme_stylebox_override("panel", estilo)

		var v := VBoxContainer.new()
		painel.add_child(v)
		var titulo := label("%s  MAPA %d — %s" % [mapa["emoji"], i + 1, String(mapa["nome"]).to_upper()], 32,
				Color.WHITE if aberto else Color("#666677"))
		v.add_child(titulo)
		var sub := label("%s  •  %s" % [mapa["dificuldade"], mapa["desc"]], 21,
				Color("#b0bec5") if aberto else Color("#555566"))
		sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(sub)
		var progresso := label("", 24, Color("#ffe082"))
		if aberto:
			progresso.text = "Desafiantes vencidos: %d/6" % Campaign.vitorias_no_mapa(Save.dados, mapa)
		else:
			progresso.text = "🔒 Vença o Guardião do mapa anterior"
		v.add_child(progresso)

		if aberto:
			var idx := i
			painel.gui_input.connect(func(ev):
				if ev is InputEventMouseButton and ev.pressed:
					Ctx.mapa_atual = idx
					get_tree().change_scene_to_file("res://game/campaign/trail.tscn"))
		lista.add_child(painel)
