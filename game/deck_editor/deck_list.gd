extends ScreenBase
## Lista de baralhos do jogador. Decks emprestados (Parte 5) não podem ser
## editados nem excluídos — duplique para personalizar.

var db: CardDB
var _lista: VBoxContainer


func _ready() -> void:
	db = CardDB.load_default()
	montar_base("Baralhos")
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	conteudo.add_child(scroll)
	_lista = VBoxContainer.new()
	_lista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lista.add_theme_constant_override("separation", 12)
	scroll.add_child(_lista)

	var novo := botao("＋ Novo baralho", _novo_deck, 30)
	conteudo.add_child(novo)
	_popular()


func _popular() -> void:
	for filho in _lista.get_children():
		filho.queue_free()
	var decks: Array = Save.dados["decks"]
	for i in decks.size():
		_lista.add_child(_painel_deck(i, decks[i]))


func _painel_deck(idx: int, deck: Dictionary) -> Control:
	var painel := PanelContainer.new()
	var ativo := int(Save.dados["deck_ativo"]) == idx
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color("#26224a") if not ativo else Color("#31406e")
	estilo.border_color = Color("#7df9ff") if ativo else Color("#3a3660")
	for b in ["border_width_left", "border_width_right", "border_width_top", "border_width_bottom"]:
		estilo.set(b, 3)
	for c in ["corner_radius_top_left", "corner_radius_top_right", "corner_radius_bottom_left", "corner_radius_bottom_right"]:
		estilo.set(c, 12)
	for m in ["content_margin_left", "content_margin_right", "content_margin_top", "content_margin_bottom"]:
		estilo.set(m, 14)
	painel.add_theme_stylebox_override("panel", estilo)

	var v := VBoxContainer.new()
	painel.add_child(v)
	var cartas: Array = deck["cartas"]
	var erros := Rules.validar_deck(db, cartas)
	var titulo := label("%s%s%s" % [deck["nome"],
			"  📌" if ativo else "",
			"  (emprestado)" if deck.get("emprestado", false) else ""], 30)
	v.add_child(titulo)
	var sub := label("%d/20 cartas  •  %s" % [cartas.size(),
			"✓ válido" if erros.is_empty() else "✗ " + erros[0]], 22,
			Color("#a5d6a7") if erros.is_empty() else Color("#ef9a9a"))
	v.add_child(sub)

	var botoes := HBoxContainer.new()
	botoes.add_theme_constant_override("separation", 10)
	v.add_child(botoes)
	if not ativo and erros.is_empty():
		botoes.add_child(botao("Usar", func():
			Save.dados["deck_ativo"] = idx
			Save.salvar()
			_popular(), 24))
	if not deck.get("emprestado", false):
		botoes.add_child(botao("Editar", func():
			Ctx.deck_em_edicao = idx
			get_tree().change_scene_to_file("res://game/deck_editor/deck_editor.tscn"), 24))
	botoes.add_child(botao("Duplicar", func():
		var copia := {"nome": String(deck["nome"]) + " (cópia)", "cartas": cartas.duplicate(), "emprestado": false}
		Save.dados["decks"].append(copia)
		Save.salvar()
		_popular(), 24))
	if not deck.get("emprestado", false) and (Save.dados["decks"] as Array).size() > 1:
		botoes.add_child(botao("Excluir", func():
			Save.dados["decks"].remove_at(idx)
			if int(Save.dados["deck_ativo"]) >= (Save.dados["decks"] as Array).size():
				Save.dados["deck_ativo"] = 0
			Save.salvar()
			_popular(), 24))
	return painel


func _novo_deck() -> void:
	Save.dados["decks"].append({"nome": "Novo baralho", "cartas": [], "emprestado": false})
	Save.salvar()
	Ctx.deck_em_edicao = (Save.dados["decks"] as Array).size() - 1
	get_tree().change_scene_to_file("res://game/deck_editor/deck_editor.tscn")
