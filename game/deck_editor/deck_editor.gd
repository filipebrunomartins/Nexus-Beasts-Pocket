extends ScreenBase
## Editor de baralho com validação em tempo real (20 cartas, máx. 2 por nome,
## ≥1 besta Básica) usando apenas cartas da coleção.

var db: CardDB
var deck_idx: int
var _nome_edit: LineEdit
var _lbl_status: Label
var _grade_deck: GridContainer
var _grade_colecao: GridContainer
var filtro_tipo := ""


func _ready() -> void:
	db = CardDB.load_default()
	deck_idx = Ctx.deck_em_edicao
	if deck_idx < 0 or deck_idx >= (Save.dados["decks"] as Array).size():
		get_tree().change_scene_to_file("res://game/deck_editor/deck_list.tscn")
		return
	montar_base("Editor de Baralho")
	# o voltar padrão vai à Home; aqui volta para a lista
	var voltar: Button = conteudo.get_child(0).get_child(0)
	voltar.pressed.disconnect(voltar.pressed.get_connections()[0]["callable"])
	voltar.pressed.connect(func(): get_tree().change_scene_to_file("res://game/deck_editor/deck_list.tscn"))

	var linha_nome := HBoxContainer.new()
	conteudo.add_child(linha_nome)
	_nome_edit = LineEdit.new()
	_nome_edit.text = _deck()["nome"]
	_nome_edit.add_theme_font_size_override("font_size", 28)
	_nome_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_nome_edit.text_changed.connect(func(t):
		_deck()["nome"] = t
		Save.salvar())
	linha_nome.add_child(_nome_edit)

	_lbl_status = label("", 24)
	conteudo.add_child(_lbl_status)

	conteudo.add_child(label("Baralho (toque para remover):", 22, Color("#b0bec5")))
	var scroll_deck := ScrollContainer.new()
	scroll_deck.custom_minimum_size = Vector2(0, 480)
	conteudo.add_child(scroll_deck)
	_grade_deck = _nova_grade()
	scroll_deck.add_child(_grade_deck)

	var linha_col := HBoxContainer.new()
	conteudo.add_child(linha_col)
	linha_col.add_child(label("Coleção (toque para adicionar):", 22, Color("#b0bec5")))
	var tipos := OptionButton.new()
	tipos.add_theme_font_size_override("font_size", 22)
	tipos.add_item("Todos")
	tipos.set_item_metadata(0, "")
	var i := 1
	for tipo in db.types.values():
		tipos.add_item("%s %s" % [tipo["simbolo"], tipo["nome"]])
		tipos.set_item_metadata(i, tipo["id"])
		i += 1
	tipos.add_item("🎴 Aliados")
	tipos.set_item_metadata(i, "aliados")
	tipos.item_selected.connect(func(idx):
		filtro_tipo = tipos.get_item_metadata(idx)
		_popular_colecao())
	linha_col.add_child(tipos)

	var scroll_col := ScrollContainer.new()
	scroll_col.size_flags_vertical = Control.SIZE_EXPAND_FILL
	conteudo.add_child(scroll_col)
	_grade_colecao = _nova_grade()
	scroll_col.add_child(_grade_colecao)

	_atualizar()


func _deck() -> Dictionary:
	return Save.dados["decks"][deck_idx]


func _nova_grade() -> GridContainer:
	var g := GridContainer.new()
	g.columns = 5
	g.add_theme_constant_override("h_separation", 10)
	g.add_theme_constant_override("v_separation", 10)
	g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return g


func _atualizar() -> void:
	var cartas: Array = _deck()["cartas"]
	var erros := Rules.validar_deck(db, cartas)
	if erros.is_empty():
		_lbl_status.text = "✓ %d/20 — baralho válido" % cartas.size()
		_lbl_status.add_theme_color_override("font_color", Color("#a5d6a7"))
	else:
		_lbl_status.text = "%d/20 — %s" % [cartas.size(), erros[0]]
		_lbl_status.add_theme_color_override("font_color", Color("#ef9a9a"))
	_popular_deck()
	_popular_colecao()


func _popular_deck() -> void:
	for filho in _grade_deck.get_children():
		filho.queue_free()
	var contagem := {}
	for id in _deck()["cartas"]:
		contagem[id] = int(contagem.get(id, 0)) + 1
	var ids := contagem.keys()
	ids.sort()
	for id in ids:
		var mini := MiniCard.nova(db, id, contagem[id])
		mini.tocada.connect(_remover)
		_grade_deck.add_child(mini)


func _popular_colecao() -> void:
	for filho in _grade_colecao.get_children():
		filho.queue_free()
	var cartas: Array = _deck()["cartas"]
	for card in db.all_cards():
		var id: String = card["id"]
		var possuidas := Save.qtd_na_colecao(id)
		if possuidas <= 0:
			continue
		if filtro_tipo == "aliados":
			if card["categoria"] == "besta":
				continue
		elif filtro_tipo != "" and card.get("tipo", "") != filtro_tipo:
			continue
		var no_deck := cartas.count(id)
		var disponiveis := mini(possuidas, 2) - no_deck
		# possuída sempre true: esgotada ≠ não descoberta (o nome fica visível)
		var mini_c := MiniCard.nova(db, id, disponiveis, true)
		mini_c.modulate = Color(1, 1, 1, 1.0 if disponiveis > 0 else 0.45)
		mini_c.tocada.connect(_adicionar)
		_grade_colecao.add_child(mini_c)


func _adicionar(id: String) -> void:
	var cartas: Array = _deck()["cartas"]
	if cartas.size() >= Rules.TAMANHO_DECK:
		return
	var nome: String = db.get_card(id)["nome"]
	var mesmo_nome := 0
	for c in cartas:
		if db.get_card(c)["nome"] == nome:
			mesmo_nome += 1
	if mesmo_nome >= 2 or cartas.count(id) >= Save.qtd_na_colecao(id):
		return
	cartas.append(id)
	Save.salvar()
	_atualizar()


func _remover(id: String) -> void:
	var cartas: Array = _deck()["cartas"]
	var idx := cartas.find(id)
	if idx >= 0:
		cartas.remove_at(idx)
		Save.salvar()
		_atualizar()
