extends ScreenBase
## Trilha de 6 desafiantes de um mapa. Também processa o resultado da última
## batalha de campanha (recompensas, estrelas, dupla dos Gêmeos).

var db: CardDB
var mapas: Array
var mapa: Dictionary


func _ready() -> void:
	db = CardDB.load_default()
	mapas = Campaign.carregar()
	mapa = mapas[Ctx.mapa_atual]
	montar_base("%s %s" % [mapa["emoji"], mapa["nome"]])
	# voltar → seleção de mapas
	var voltar: Button = conteudo.get_child(0).get_child(0)
	voltar.pressed.disconnect(voltar.pressed.get_connections()[0]["callable"])
	voltar.pressed.connect(func(): get_tree().change_scene_to_file("res://game/campaign/map_select.tscn"))

	# Estrelas do mapa e resgate automático de marcos (pacotes bônus)
	var estrelas_mapa := Campaign.estrelas_do_mapa(Save.dados, mapa)
	var pacotes_marco := Campaign.resgatar_marcos(Save.dados, mapa)
	if pacotes_marco > 0:
		Save.salvar()
	var lbl_estrelas := label("★ %d/18 — pacotes bônus a 6★, 12★ e 18★" % estrelas_mapa, 22, Color("#ffe082"))
	lbl_estrelas.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	conteudo.add_child(lbl_estrelas)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	conteudo.add_child(scroll)
	var lista := VBoxContainer.new()
	lista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lista.add_theme_constant_override("separation", 14)
	scroll.add_child(lista)

	for i in (mapa["desafiantes"] as Array).size():
		lista.add_child(_painel_desafiante(i))

	_processar_resultado()


func _painel_desafiante(idx: int) -> Control:
	var des: Dictionary = mapa["desafiantes"][idx]
	var aberto := Campaign.desafiante_desbloqueado(Save.dados, mapa, idx)
	var vencido := Campaign.venceu(Save.dados, des["id"])
	var estrelas := Campaign.estrelas(Save.dados, des["id"])

	var painel := PanelContainer.new()
	var estilo := StyleBoxFlat.new()
	var eh_guardiao: bool = des.get("guardiao", false)
	estilo.bg_color = Color("#3d2a10") if eh_guardiao and aberto else (Color("#26224a") if aberto else Color("#1a1830"))
	estilo.border_color = Color("#ffd54f") if eh_guardiao and aberto else (Color("#5c6bc0") if aberto else Color("#2a2845"))
	for b in ["border_width_left", "border_width_right", "border_width_top", "border_width_bottom"]:
		estilo.set(b, 3)
	for c in ["corner_radius_top_left", "corner_radius_top_right", "corner_radius_bottom_left", "corner_radius_bottom_right"]:
		estilo.set(c, 14)
	for m in ["content_margin_left", "content_margin_right", "content_margin_top", "content_margin_bottom"]:
		estilo.set(m, 14)
	painel.add_theme_stylebox_override("panel", estilo)

	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 16)
	painel.add_child(h)
	var retrato := label(des["emoji"] if aberto else "🔒", 56)
	retrato.custom_minimum_size = Vector2(90, 0)
	h.add_child(retrato)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	v.add_child(label("%d. %s" % [idx + 1, des["nome"] if aberto else "???"], 28,
			Color.WHITE if aberto else Color("#666677")))
	if aberto:
		v.add_child(label(des["perfil"], 20, Color("#b0bec5")))
		var status_txt := "★".repeat(estrelas) + "☆".repeat(3 - estrelas) if vencido else "não vencido"
		v.add_child(label("%s   %s" % [status_txt, _texto_recompensa(des, vencido)], 21, Color("#ffe082")))
	if aberto:
		painel.gui_input.connect(func(ev):
			if ev is InputEventMouseButton and ev.pressed:
				_abrir_pre_batalha(des))
	return painel


func _texto_recompensa(des: Dictionary, vencido: bool) -> String:
	if vencido:
		return "revanche: 💰20"
	var r: Dictionary = des["recompensa"]
	var partes: PackedStringArray = []
	if r.has("moedas"): partes.append("💰%d" % r["moedas"])
	if r.has("pacotes"): partes.append("🎁×%d" % r["pacotes"])
	if r.has("ampulhetas"): partes.append("⏳×%d" % r["ampulhetas"])
	if r.has("carta"): partes.append("🎴 " + db.get_card(r["carta"])["nome"])
	if r.has("titulo"): partes.append("👑 título")
	return " ".join(partes)


func _abrir_pre_batalha(des: Dictionary) -> void:
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.8)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(centro)
	var painel := PanelContainer.new()
	painel.custom_minimum_size = Vector2(860, 0)
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color("#1a1440")
	estilo.border_color = Color("#c86bff")
	for b in ["border_width_left", "border_width_right", "border_width_top", "border_width_bottom"]:
		estilo.set(b, 3)
	for c in ["corner_radius_top_left", "corner_radius_top_right", "corner_radius_bottom_left", "corner_radius_bottom_right"]:
		estilo.set(c, 20)
	for m in ["content_margin_left", "content_margin_right", "content_margin_top", "content_margin_bottom"]:
		estilo.set(m, 30)
	painel.add_theme_stylebox_override("panel", estilo)
	centro.add_child(painel)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 16)
	painel.add_child(v)
	var retrato := label(des["emoji"], 110)
	retrato.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(retrato)
	var nome := label(des["nome"], 36)
	nome.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(nome)
	var fala := label("“%s”" % des["fala"], 24, Color("#d1c4e9"))
	fala.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fala.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(fala)

	var botoes := HBoxContainer.new()
	botoes.alignment = BoxContainer.ALIGNMENT_CENTER
	botoes.add_theme_constant_override("separation", 20)
	v.add_child(botoes)
	botoes.add_child(botao("⚔ Batalhar!", func(): _iniciar_batalha(des), 30))
	botoes.add_child(botao("Fechar", func(): overlay.queue_free(), 26))


func _iniciar_batalha(des: Dictionary, fase_dupla := 1) -> void:
	var regras: Array = des.get("regras", [])
	var deck_ia: Array
	if regras.has("espelho"):
		deck_ia = (Save.dados["decks"][int(Save.dados["deck_ativo"])]["cartas"] as Array).duplicate()
	elif regras.has("sorteio"):
		var opcoes: Array = des["decks_sorteio"]
		deck_ia = opcoes[randi() % opcoes.size()]
	elif regras.has("dupla") and fase_dupla == 2:
		deck_ia = des["deck2"]
	else:
		deck_ia = des["deck"]

	Ctx.batalha = {
		"campanha": true,
		"desafiante_id": des["id"],
		"mapa_idx": Ctx.mapa_atual,
		"deck_ia": deck_ia,
		"tipos_ia": Rules.sugerir_tipos_mana(db, deck_ia),
		"nivel_ia": int(mapa["nivel_ia"]),
		"nome_oponente": des["nome"] if not regras.has("dupla") else ("Turbo" if fase_dupla == 1 else "Trovão"),
		"regras": regras,
		"fase_dupla": fase_dupla,
	}
	get_tree().change_scene_to_file("res://game/battle/battle.tscn")


## Chamado ao voltar de uma batalha de campanha.
func _processar_resultado() -> void:
	if Ctx.resultado.is_empty() or Ctx.batalha.is_empty():
		return
	var res := Ctx.resultado
	var cfg := Ctx.batalha
	Ctx.resultado = {}
	var des := _achar_desafiante(cfg["desafiante_id"])

	# Gêmeos: venceu a 1ª → encara a 2ª imediatamente (dano de cansaço).
	if (cfg["regras"] as Array).has("dupla") and int(cfg["fase_dupla"]) == 1 and res["venceu"]:
		Ctx.batalha = {}
		_popup("Turbo caiu!", ["Agora é a vez de TROVÃO!\nSuas Bestas entram cansadas (10 de dano)."],
				func(): _iniciar_batalha(des, 2))
		return

	Ctx.batalha = {}
	if res["venceu"]:
		var ganhos := Campaign.registrar_resultado(Save.dados, des, true,
				int(res["selos_oponente"]), int(res["turnos"]))
		Save.salvar()
		var estrelas := Campaign.calcular_estrelas(true, int(res["selos_oponente"]), int(res["turnos"]))
		_popup("VITÓRIA!  %s" % ("★".repeat(estrelas) + "☆".repeat(3 - estrelas)),
				ganhos, func(): get_tree().reload_current_scene())
	else:
		_popup("Derrota...", ["Treine e tente de novo — a revanche está liberada."], func(): pass)


func _achar_desafiante(id: String) -> Dictionary:
	for m in mapas:
		for d in m["desafiantes"]:
			if d["id"] == id:
				return d
	return {}


func _popup(titulo: String, linhas: PackedStringArray, ao_fechar: Callable) -> void:
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.8)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(centro)
	var painel := PanelContainer.new()
	painel.custom_minimum_size = Vector2(760, 0)
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color("#1a1440")
	estilo.border_color = Color("#ffd54f")
	for b in ["border_width_left", "border_width_right", "border_width_top", "border_width_bottom"]:
		estilo.set(b, 3)
	for c in ["corner_radius_top_left", "corner_radius_top_right", "corner_radius_bottom_left", "corner_radius_bottom_right"]:
		estilo.set(c, 20)
	for m in ["content_margin_left", "content_margin_right", "content_margin_top", "content_margin_bottom"]:
		estilo.set(m, 30)
	painel.add_theme_stylebox_override("panel", estilo)
	centro.add_child(painel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	painel.add_child(v)
	var t := label(titulo, 38)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	for linha in linhas:
		var l := label(linha, 26, Color("#ffe082"))
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(l)
	var btn := botao("OK", func():
		overlay.queue_free()
		ao_fechar.call(), 28)
	v.add_child(btn)
