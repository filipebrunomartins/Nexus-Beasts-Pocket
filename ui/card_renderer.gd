class_name CardRenderer
extends PanelContainer
## Renderizador de carta orientado a dados (template 6.1 do design).
## Arte placeholder: gradiente + símbolo do tipo. Trocar por ilustrações
## finais = apenas apontar "ilustracao" para uma textura por carta.

const LARGURA := 520.0
const ALTURA := 760.0
const COR_RARIDADE := {1: "#b0bec5", 2: "#81d4fa", 3: "#ffd54f", 4: "#ff8a65", 5: "#ea80fc"}

var db: CardDB
var card: Dictionary


static func nova(db_: CardDB, card_id: String) -> CardRenderer:
	var r := CardRenderer.new()
	r.db = db_
	r.card = db_.get_card(card_id)
	r.custom_minimum_size = Vector2(LARGURA, ALTURA)
	r._montar()
	return r


func _cor_tipo() -> Color:
	var tipo_id: String = card["reliquia"]["tipo"] if card["categoria"] == "reliquia" else card.get("tipo", "neutro")
	if card["categoria"] in ["mentor", "item", "ferramenta"]:
		return Color("#546e7a")
	return Color(db.get_type(tipo_id)["cor"])


func _simbolo_tipo() -> String:
	var tipo_id: String = card["reliquia"]["tipo"] if card["categoria"] == "reliquia" else card.get("tipo", "")
	if tipo_id == "":
		return {"mentor": "🎓", "item": "🎒", "ferramenta": "🔧"}.get(card["categoria"], "❔")
	return db.get_type(tipo_id)["simbolo"]


func _montar() -> void:
	var cor := _cor_tipo()
	var moldura := StyleBoxFlat.new()
	moldura.bg_color = cor.darkened(0.72)
	moldura.border_color = Color(COR_RARIDADE.get(int(card.get("raridade", 1)), "#b0bec5"))
	for b in ["border_width_left", "border_width_right", "border_width_top", "border_width_bottom"]:
		moldura.set(b, 6)
	for c in ["corner_radius_top_left", "corner_radius_top_right", "corner_radius_bottom_left", "corner_radius_bottom_right"]:
		moldura.set(c, 22)
	for m in ["content_margin_left", "content_margin_right"]:
		moldura.set(m, 18)
	moldura.content_margin_top = 14
	moldura.content_margin_bottom = 14
	add_theme_stylebox_override("panel", moldura)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	add_child(v)

	v.add_child(_linha_cabecalho())
	v.add_child(_linha_nome())
	v.add_child(_ilustracao(cor))
	if card["categoria"] == "besta":
		_montar_besta(v)
	else:
		_montar_aliado(v)


func _linha_cabecalho() -> Control:
	var h := HBoxContainer.new()
	var esq := _label(20, Color("#cfd8dc"))
	match card["categoria"]:
		"besta":
			var estagio: String = ["BÁSICO", "ESTÁGIO 1", "ESTÁGIO 2"][int(card["estagio"])]
			if card.get("omega", false):
				estagio = "BÁSICO Ω"
			esq.text = estagio
			if card["evolui_de"] != null:
				esq.text += "  (evolui de %s)" % db.get_card(card["evolui_de"])["nome"]
		"mentor": esq.text = "ALIADO — MENTOR"
		"item": esq.text = "ALIADO — ITEM"
		"ferramenta": esq.text = "ALIADO — FERRAMENTA"
		"reliquia": esq.text = "ALIADO — ITEM RELÍQUIA"
	h.add_child(esq)
	var espaco := Control.new()
	espaco.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(espaco)
	var raridade := _label(22, Color(COR_RARIDADE.get(int(card.get("raridade", 1)), "#b0bec5")))
	var r := int(card.get("raridade", 1))
	raridade.text = "★" if r >= 5 else "♦".repeat(r)
	h.add_child(raridade)
	return h


func _linha_nome() -> Control:
	var h := HBoxContainer.new()
	var nome := _label(34, Color.WHITE)
	nome.text = card["nome"]
	nome.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nome.clip_text = true
	h.add_child(nome)
	if card["categoria"] == "besta":
		var ps := _label(30, Color("#ffcc80"))
		ps.text = "PS %d " % card["ps"]
		h.add_child(ps)
		var tipo := _label(30, Color.WHITE)
		tipo.text = _simbolo_tipo()
		h.add_child(tipo)
	elif card["categoria"] == "reliquia":
		var ps := _label(30, Color("#ffcc80"))
		ps.text = "PS %d ⭐" % card["reliquia"]["ps"]
		h.add_child(ps)
	return h


## Placeholder de arte: gradiente do tipo + símbolo grande + "assinatura" da carta.
func _ilustracao(cor: Color) -> Control:
	var painel := PanelContainer.new()
	painel.custom_minimum_size = Vector2(0, 240)
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = cor.darkened(0.35)
	estilo.border_color = cor.lightened(0.15)
	for b in ["border_width_left", "border_width_right", "border_width_top", "border_width_bottom"]:
		estilo.set(b, 2)
	for c in ["corner_radius_top_left", "corner_radius_top_right", "corner_radius_bottom_left", "corner_radius_bottom_right"]:
		estilo.set(c, 14)
	painel.add_theme_stylebox_override("panel", estilo)

	var centro := CenterContainer.new()
	painel.add_child(centro)
	var simbolo := _label(130, cor.lightened(0.45))
	simbolo.text = _simbolo_tipo()
	centro.add_child(simbolo)

	# Marca d'água com a inicial — dá identidade única a cada carta sem arte
	var inicial := _label(64, Color(cor.lightened(0.7), 0.35))
	inicial.text = String(card["nome"]).left(1)
	inicial.set_anchors_preset(Control.PRESET_TOP_LEFT)
	inicial.position = Vector2(16, 4)
	painel.add_child(inicial)
	return painel


func _montar_besta(v: VBoxContainer) -> void:
	var hab: Variant = card.get("habilidade")
	if hab != null:
		var caixa := _caixa_texto()
		var titulo := _label(24, Color("#ce93d8"))
		titulo.text = "✦ %s" % hab["nome"]
		caixa.get_child(0).add_child(titulo)
		var texto := _texto_corrido(hab["texto"])
		caixa.get_child(0).add_child(texto)
		v.add_child(caixa)

	for atk in card["ataques"]:
		var caixa := _caixa_texto()
		var linha := HBoxContainer.new()
		var custo := _label(26, Color.WHITE)
		var custo_txt := ""
		for c in atk["custo"]:
			custo_txt += "⭐" if c == "qualquer" else String(db.get_type(c)["simbolo"])
		custo.text = custo_txt + " "
		linha.add_child(custo)
		var nome := _label(26, Color.WHITE)
		nome.text = atk["nome"]
		nome.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nome.clip_text = true
		linha.add_child(nome)
		if int(atk["dano"]) > 0:
			var dano := _label(30, Color("#ff8a80"))
			var mais := "+" if not (atk["efeitos"] as Array).filter(
					func(e): return e["bloco"] in ["moedas_dano", "dano_bonus_se", "dano_por_energia_extra"]).is_empty() else ""
			dano.text = "%d%s" % [atk["dano"], mais]
			linha.add_child(dano)
		caixa.get_child(0).add_child(linha)
		if atk["texto"] != null:
			caixa.get_child(0).add_child(_texto_corrido(atk["texto"]))
		v.add_child(caixa)

	var espaco := Control.new()
	espaco.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(espaco)

	var rodape := HBoxContainer.new()
	var fraqueza := _label(24, Color("#b0bec5"))
	if card["fraqueza"] != null:
		fraqueza.text = "Fraqueza: %s +20" % db.get_type(card["fraqueza"])["simbolo"]
	else:
		fraqueza.text = "Fraqueza: —"
	rodape.add_child(fraqueza)
	var meio := Control.new()
	meio.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rodape.add_child(meio)
	var recuo := _label(24, Color("#b0bec5"))
	recuo.text = "Recuo: %s" % ("0" if int(card["recuo"]) == 0 else "⭐".repeat(int(card["recuo"])))
	rodape.add_child(recuo)
	v.add_child(rodape)


func _montar_aliado(v: VBoxContainer) -> void:
	var caixa := _caixa_texto()
	caixa.get_child(0).add_child(_texto_corrido(card["texto"]))
	v.add_child(caixa)

	var espaco := Control.new()
	espaco.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(espaco)

	var regra := _label(20, Color("#90a4ae"))
	regra.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	match card["categoria"]:
		"mentor":
			regra.text = "Você só pode jogar 1 Mentor por turno."
		"item":
			regra.text = "Jogue quantos Itens quiser por turno."
		"ferramenta":
			regra.text = "Anexe a 1 dos seus monstros (1 Ferramenta por monstro)."
		"reliquia":
			regra.text = "Entra em jogo como uma Besta Básica. Não concede Selo ao ser nocauteada."
	v.add_child(regra)


func _caixa_texto() -> PanelContainer:
	var caixa := PanelContainer.new()
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0, 0, 0, 0.25)
	for c in ["corner_radius_top_left", "corner_radius_top_right", "corner_radius_bottom_left", "corner_radius_bottom_right"]:
		estilo.set(c, 10)
	for m in ["content_margin_left", "content_margin_right", "content_margin_top", "content_margin_bottom"]:
		estilo.set(m, 10)
	caixa.add_theme_stylebox_override("panel", estilo)
	var v := VBoxContainer.new()
	caixa.add_child(v)
	return caixa


func _texto_corrido(texto: String) -> Label:
	var l := _label(21, Color("#eceff1"))
	l.text = texto
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


func _label(tamanho: int, cor: Color) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", tamanho)
	l.add_theme_color_override("font_color", cor)
	return l
