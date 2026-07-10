extends ScreenBase
## Coleção/Álbum: grade das 79 cartas com filtros por tipo e raridade.
## Cartas não possuídas aparecem como silhueta "???".

var db: CardDB
var filtro_tipo := ""     # "" = todos
var filtro_raridade := 0  # 0 = todas
var _grade: GridContainer


func _ready() -> void:
	db = CardDB.load_default()
	montar_base("Coleção")

	var resumo := label("%d / %d cartas descobertas" % [Save.total_cartas_unicas(), db.cards.size()], 24, Color("#b0bec5"))
	resumo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	conteudo.add_child(resumo)

	conteudo.add_child(_montar_filtros())

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	conteudo.add_child(scroll)
	_grade = GridContainer.new()
	_grade.columns = 5
	_grade.add_theme_constant_override("h_separation", 10)
	_grade.add_theme_constant_override("v_separation", 10)
	_grade.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_grade)
	_popular()


func _montar_filtros() -> Control:
	var barra := HBoxContainer.new()
	barra.add_theme_constant_override("separation", 8)

	var tipos := OptionButton.new()
	tipos.add_theme_font_size_override("font_size", 24)
	tipos.add_item("Todos os tipos")
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
		_popular())
	barra.add_child(tipos)

	var raridades := OptionButton.new()
	raridades.add_theme_font_size_override("font_size", 24)
	raridades.add_item("Toda raridade")
	for r in [1, 2, 3, 4]:
		raridades.add_item("♦".repeat(r))
	raridades.item_selected.connect(func(idx):
		filtro_raridade = idx
		_popular())
	barra.add_child(raridades)
	return barra


func _popular() -> void:
	for filho in _grade.get_children():
		filho.queue_free()
	for card in db.all_cards():
		if filtro_tipo == "aliados":
			if card["categoria"] == "besta":
				continue
		elif filtro_tipo != "" and card.get("tipo", "") != filtro_tipo:
			continue
		if filtro_raridade > 0 and int(card.get("raridade", 1)) != filtro_raridade:
			continue
		var qtd := Save.qtd_na_colecao(card["id"])
		var mini := MiniCard.nova(db, card["id"], qtd, qtd > 0)
		if qtd > 0:
			mini.tocada.connect(func(id): zoom_carta(db, id))
		_grade.add_child(mini)
