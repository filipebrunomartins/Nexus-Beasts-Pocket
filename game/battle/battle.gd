extends Control
## Tela de batalha (layout da seção 7.2). A UI é construída em código e
## re-renderizada por completo após cada ação; os botões de jogada vêm
## diretamente de Rules.acoes_legais — só existem jogadas legais.

signal batalha_terminou(vencedor_humano: bool, estado_final: Dictionary)

const CORES_STATUS := {
	"envenenado": "🟣", "queimado": "🔥", "adormecido": "💤",
	"paralisado": "⚡", "confuso": "❓",
}

var db: CardDB
var state: Dictionary
var ia: HeuristicAI
var lado_humano := 0

## Configuração da partida (a campanha sobrescreve na Etapa 9)
var deck_humano: Array = []
var tipos_humano: Array = []
var deck_ia: Array = []
var tipos_ia: Array = []
var nivel_ia := 1
var nome_oponente := "Oponente"

var _ia_agindo := false
var _fim_notificado := false
var _regras_pos_aplicadas := false

# nós principais
var _lbl_topo: Label
var _reserva_op: HBoxContainer
var _ativo_op: PanelContainer
var _lbl_log: RichTextLabel
var _ativo_eu: PanelContainer
var _reserva_eu: HBoxContainer
var _lbl_rodape: Label
var _mao_box: HBoxContainer
var _acoes_box: VBoxContainer
var _overlay_fim: PanelContainer


func _ready() -> void:
	db = CardDB.load_default()
	# Campanha (Etapa 9) configura via Ctx.batalha; batalha livre usa o deck
	# ativo do jogador contra um deck inicial aleatório.
	if not Ctx.batalha.is_empty():
		var cfg: Dictionary = Ctx.batalha
		deck_ia = cfg["deck_ia"]
		tipos_ia = cfg["tipos_ia"]
		nivel_ia = int(cfg.get("nivel_ia", 1))
		nome_oponente = cfg.get("nome_oponente", "Oponente")
	if deck_humano.is_empty():
		var salvo: Dictionary = Save.dados["decks"][clampi(int(Save.dados["deck_ativo"]), 0, (Save.dados["decks"] as Array).size() - 1)]
		var decks := CardDB.load_decks()
		if Rules.validar_deck(db, salvo["cartas"]).is_empty():
			deck_humano = (salvo["cartas"] as Array).duplicate()
		else:
			deck_humano = decks[0]["cartas"]
		tipos_humano = Rules.sugerir_tipos_mana(db, deck_humano)
	if deck_ia.is_empty():
		var decks := CardDB.load_decks()
		var sorteio: Dictionary = decks[randi() % decks.size()]
		deck_ia = sorteio["cartas"]
		tipos_ia = sorteio["tipos_mana"]
		nome_oponente = "IA — " + String(sorteio["nome"])
	state = Rules.nova_partida(db, deck_humano, deck_ia, tipos_humano, tipos_ia, randi(), -1)
	ia = HeuristicAI.new(nivel_ia, randi())
	_aplicar_regras_chefe_pre_setup()
	_construir_ui()
	_apos_mudanca()


## Regras especiais de chefe aplicadas antes do posicionamento.
func _aplicar_regras_chefe_pre_setup() -> void:
	var regras: Array = Ctx.batalha.get("regras", [])
	if regras.has("dupla") and int(Ctx.batalha.get("fase_dupla", 1)) == 2:
		# 2ª batalha dos Gêmeos: suas Bestas entram cansadas (10 de dano)
		state["modificadores"] = {"dano_ao_entrar": {lado_humano: 10}}


## Regras de chefe aplicadas quando a batalha começa (pós-posicionamento).
func _aplicar_regras_chefe_pos_setup() -> void:
	if _regras_pos_aplicadas or state["fase"] != "jogando":
		return
	_regras_pos_aplicadas = true
	var regras: Array = Ctx.batalha.get("regras", [])
	var ativo_ia: Variant = Rules.jogador(state, 1 - lado_humano)["ativo"]
	if ativo_ia == null:
		return
	if regras.has("ferramenta_inicial") and ativo_ia["ferramenta"] == null:
		ativo_ia["ferramenta"] = "AL-016"
		state["log"].append("Regra de chefe: %s começa com Garra Afiada!" % nome_oponente)
	if regras.has("mana_extra"):
		var tipo: String = tipos_ia[0] if not tipos_ia.is_empty() else "flora"
		ativo_ia["energias"].append(tipo)
		state["log"].append("Regra de chefe: %s começa com 1 mana extra!" % nome_oponente)


# ============================================================ construção

func _construir_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color("14102b")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var raiz := MarginContainer.new()
	raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	for m in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		raiz.add_theme_constant_override(m, 16)
	add_child(raiz)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	raiz.add_child(col)

	_lbl_topo = _novo_label(30)
	col.add_child(_lbl_topo)

	_reserva_op = HBoxContainer.new()
	_reserva_op.alignment = BoxContainer.ALIGNMENT_CENTER
	_reserva_op.add_theme_constant_override("separation", 8)
	col.add_child(_reserva_op)

	var centro_op := HBoxContainer.new()
	centro_op.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_child(centro_op)
	_ativo_op = _novo_slot()
	centro_op.add_child(_ativo_op)

	_lbl_log = RichTextLabel.new()
	_lbl_log.bbcode_enabled = true
	_lbl_log.scroll_following = true
	_lbl_log.custom_minimum_size = Vector2(0, 170)
	_lbl_log.add_theme_font_size_override("normal_font_size", 24)
	col.add_child(_lbl_log)

	var centro_eu := HBoxContainer.new()
	centro_eu.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_child(centro_eu)
	_ativo_eu = _novo_slot()
	centro_eu.add_child(_ativo_eu)

	_reserva_eu = HBoxContainer.new()
	_reserva_eu.alignment = BoxContainer.ALIGNMENT_CENTER
	_reserva_eu.add_theme_constant_override("separation", 8)
	col.add_child(_reserva_eu)

	_lbl_rodape = _novo_label(30)
	col.add_child(_lbl_rodape)

	var scroll_mao := ScrollContainer.new()
	scroll_mao.custom_minimum_size = Vector2(0, 150)
	scroll_mao.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	col.add_child(scroll_mao)
	_mao_box = HBoxContainer.new()
	_mao_box.add_theme_constant_override("separation", 8)
	scroll_mao.add_child(_mao_box)

	var scroll_acoes := ScrollContainer.new()
	scroll_acoes.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(scroll_acoes)
	_acoes_box = VBoxContainer.new()
	_acoes_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_acoes_box.add_theme_constant_override("separation", 6)
	scroll_acoes.add_child(_acoes_box)


func _novo_label(tamanho: int) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", tamanho)
	return l


func _novo_slot() -> PanelContainer:
	var painel := PanelContainer.new()
	painel.custom_minimum_size = Vector2(300, 150)
	return painel

# ============================================================ renderização

func _apos_mudanca() -> void:
	_aplicar_regras_chefe_pos_setup()
	_render()
	if state["fase"] == "fim":
		_mostrar_fim()
		return
	if MatchRunner.lado_agindo(state) != lado_humano and not _ia_agindo:
		_rodar_ia()


func _render() -> void:
	var op := Rules.jogador(state, 1 - lado_humano)
	var eu := Rules.jogador(state, lado_humano)

	_lbl_topo.text = "%s   ⭐%d selos   🂠%d deck   ✋%d" % [
		nome_oponente, op["selos"], (op["deck"] as Array).size(), (op["mao"] as Array).size()]

	_preencher_slot(_ativo_op, op["ativo"], true)
	_preencher_reserva(_reserva_op, op["reserva"])
	_preencher_slot(_ativo_eu, eu["ativo"], true)
	_preencher_reserva(_reserva_eu, eu["reserva"])

	var mana_txt := "mana: %s → próx: %s" % [
		_icone_mana(eu["mana_atual"]), _icone_mana(eu["proxima_mana"])]
	if eu["mana_anexada"]:
		mana_txt = "mana usada → próx: %s" % _icone_mana(eu["proxima_mana"])
	_lbl_rodape.text = "VOCÊ   ⭐%d selos   🂠%d deck   %s   Turno %d" % [
		eu["selos"], (eu["deck"] as Array).size(), mana_txt, state["turno"]]

	# log: últimas 8 linhas
	var linhas: Array = (state["log"] as Array).slice(maxi((state["log"] as Array).size() - 8, 0))
	_lbl_log.text = "\n".join(PackedStringArray(linhas))

	_render_mao(eu)
	_render_acoes()


func _icone_mana(tipo: String) -> String:
	if tipo == "":
		return "—"
	return db.get_type(tipo)["simbolo"] + db.get_type(tipo)["nome"]


func _preencher_reserva(box: HBoxContainer, reserva: Array) -> void:
	for filho in box.get_children():
		filho.queue_free()
	for i in Rules.LIMITE_RESERVA:
		var slot := _novo_slot()
		slot.custom_minimum_size = Vector2(220, 130)
		_preencher_slot(slot, reserva[i] if i < reserva.size() else null, false)
		box.add_child(slot)


func _preencher_slot(painel: PanelContainer, besta: Variant, grande: bool) -> void:
	for filho in painel.get_children():
		filho.queue_free()
	var estilo := StyleBoxFlat.new()
	estilo.corner_radius_top_left = 10
	estilo.corner_radius_top_right = 10
	estilo.corner_radius_bottom_left = 10
	estilo.corner_radius_bottom_right = 10
	if besta == null:
		estilo.bg_color = Color("22203a")
		painel.add_theme_stylebox_override("panel", estilo)
		return
	var card := Rules.carta_de(db, besta)
	var tipo_id: String = card["reliquia"]["tipo"] if card["categoria"] == "reliquia" else card["tipo"]
	estilo.bg_color = Color(db.get_type(tipo_id)["cor"]).darkened(0.45)
	estilo.border_color = Color(db.get_type(tipo_id)["cor"])
	for b in ["border_width_left", "border_width_right", "border_width_top", "border_width_bottom"]:
		estilo.set(b, 3)
	painel.add_theme_stylebox_override("panel", estilo)

	var v := VBoxContainer.new()
	painel.add_child(v)
	var nome := _novo_label(26 if grande else 22)
	nome.text = card["nome"]
	nome.clip_text = true
	v.add_child(nome)
	var ps := _novo_label(24 if grande else 20)
	ps.text = "PS %d/%d" % [Rules.ps_total(db, besta) - int(besta["dano"]), Rules.ps_total(db, besta)]
	v.add_child(ps)
	var extras := _novo_label(22 if grande else 18)
	var energia_txt := ""
	for e in besta["energias"]:
		energia_txt += db.get_type(e)["simbolo"]
	var status_txt := ""
	for s in besta["status"]:
		status_txt += CORES_STATUS.get(s["id"], "?")
	var ferramenta_txt: String = " 🔧" if besta["ferramenta"] != null else ""
	extras.text = energia_txt + " " + status_txt + ferramenta_txt
	v.add_child(extras)


func _render_mao(eu: Dictionary) -> void:
	for filho in _mao_box.get_children():
		filho.queue_free()
	for id in eu["mao"]:
		var card := db.get_card(id)
		var painel := PanelContainer.new()
		painel.custom_minimum_size = Vector2(170, 130)
		var estilo := StyleBoxFlat.new()
		estilo.corner_radius_top_left = 8
		estilo.corner_radius_top_right = 8
		estilo.corner_radius_bottom_left = 8
		estilo.corner_radius_bottom_right = 8
		var cor := "#455a64"
		if card["categoria"] == "besta":
			cor = db.get_type(card["tipo"])["cor"]
		elif card["categoria"] == "reliquia":
			cor = db.get_type(card["reliquia"]["tipo"])["cor"]
		estilo.bg_color = Color(cor).darkened(0.55)
		painel.add_theme_stylebox_override("panel", estilo)
		var v := VBoxContainer.new()
		painel.add_child(v)
		var nome := _novo_label(20)
		nome.text = card["nome"]
		nome.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(nome)
		var sub := _novo_label(18)
		sub.text = _subtitulo_carta(card)
		v.add_child(sub)
		var lupa := _novo_label(18)
		lupa.text = "🔍 ver"
		v.add_child(lupa)
		painel.gui_input.connect(_ao_tocar_carta_mao.bind(String(id)))
		_mao_box.add_child(painel)


func _subtitulo_carta(card: Dictionary) -> String:
	match card["categoria"]:
		"besta":
			var estagio: String = ["Básico", "Est. 1", "Est. 2"][int(card["estagio"])]
			return "%s • PS %d" % [estagio, card["ps"]]
		"mentor": return "Mentor"
		"item": return "Item"
		"ferramenta": return "Ferramenta"
		"reliquia": return "Relíquia"
	return ""


func _render_acoes() -> void:
	for filho in _acoes_box.get_children():
		filho.queue_free()
	if state["fase"] == "fim" or MatchRunner.lado_agindo(state) != lado_humano:
		var espera := _novo_label(26)
		espera.text = "Aguardando o oponente..." if state["fase"] != "fim" else ""
		_acoes_box.add_child(espera)
		return
	for acao in Rules.acoes_legais(db, state):
		var btn := Button.new()
		btn.text = _rotulo_acao(acao)
		btn.add_theme_font_size_override("font_size", 26)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.pressed.connect(_ao_escolher_acao.bind(acao))
		_acoes_box.add_child(btn)

# ============================================================ rótulos

func _rotulo_acao(acao: Dictionary) -> String:
	var lado: int = MatchRunner.lado_agindo(state)
	var p := Rules.jogador(state, lado)
	match acao["tipo"]:
		"posicionar_ativo":
			return "▶ Ativo inicial: %s" % db.get_card(p["mao"][acao["indice_mao"]])["nome"]
		"promover":
			return "▶ Promover %s" % Rules.carta_de(db, p["reserva"][acao["idx"]])["nome"]
		"colocar_reserva":
			return "Reserva ⟵ %s" % db.get_card(p["mao"][acao["indice_mao"]])["nome"]
		"evoluir":
			var alvo: Dictionary = Rules.besta_em(state, lado, acao["alvo"])
			var extra := "  (usar habilidade)" if acao.get("usar_gatilho", false) else ""
			return "Evoluir %s → %s%s" % [Rules.carta_de(db, alvo)["nome"], db.get_card(p["mao"][acao["indice_mao"]])["nome"], extra]
		"anexar_mana":
			var alvo: Dictionary = Rules.besta_em(state, lado, acao["alvo"])
			return "Anexar %s em %s" % [_icone_mana(p["mana_atual"]), Rules.carta_de(db, alvo)["nome"]]
		"anexar_ferramenta":
			var alvo: Dictionary = Rules.besta_em(state, lado, acao["alvo"])
			return "Equipar %s em %s" % [db.get_card(p["mao"][acao["indice_mao"]])["nome"], Rules.carta_de(db, alvo)["nome"]]
		"jogar_aliado":
			return "Jogar %s%s" % [db.get_card(p["mao"][acao["indice_mao"]])["nome"], _sufixo_alvo(acao, lado)]
		"usar_habilidade":
			var besta: Dictionary = Rules.besta_em(state, lado, acao["alvo"])
			var hab: Dictionary = Rules.carta_de(db, besta)["habilidade"]
			return "Habilidade: %s (%s)%s" % [hab["nome"], Rules.carta_de(db, besta)["nome"], _sufixo_alvo(acao, lado)]
		"descartar_reliquia":
			return "Descartar relíquia da Linha de Frente"
		"recuar":
			return "Recuar (custo %d) → %s" % [Rules.custo_recuo(db, state, lado), Rules.carta_de(db, p["reserva"][acao["indice_reserva"]])["nome"]]
		"atacar":
			var card := Rules.carta_de(db, p["ativo"])
			var atk: Dictionary = card["ataques"][acao["indice_ataque"]]
			var dano_txt: String = ("— %d" % atk["dano"]) if int(atk["dano"]) > 0 else ""
			return "⚔ %s %s%s" % [atk["nome"], dano_txt, _sufixo_alvo(acao, lado)]
		"encerrar_turno":
			return "Encerrar turno ▶"
	return str(acao)


func _sufixo_alvo(acao: Dictionary, lado: int) -> String:
	var params: Dictionary = acao.get("params", {})
	if params.has("alvo_oponente"):
		var alvo: Variant = Rules.besta_em(state, 1 - lado, params["alvo_oponente"])
		if alvo != null:
			return " → %s" % Rules.carta_de(db, alvo)["nome"]
	if params.has("alvo_proprio"):
		var alvo: Variant = Rules.besta_em(state, lado, params["alvo_proprio"])
		if alvo != null:
			return " → %s" % Rules.carta_de(db, alvo)["nome"]
	if params.has("origem"):
		return " (%s → %s)" % [params["origem"]["pos"], params["destino"]["pos"]]
	if params.has("indice_reserva"):
		var p := Rules.jogador(state, lado)
		return " → %s" % Rules.carta_de(db, p["reserva"][params["indice_reserva"]])["nome"]
	return ""

func _ao_tocar_carta_mao(event: InputEvent, card_id: String) -> void:
	if event is InputEventMouseButton and event.pressed:
		_zoom_carta(card_id)


## Overlay de zoom com a carta completa (CardRenderer); toque fecha.
func _zoom_carta(card_id: String) -> void:
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


# ============================================================ fluxo

func _ao_escolher_acao(acao: Dictionary) -> void:
	if MatchRunner.lado_agindo(state) != lado_humano:
		return
	Rules.aplicar(db, state, acao)
	_apos_mudanca()


func _rodar_ia() -> void:
	_ia_agindo = true
	while state["fase"] != "fim" and MatchRunner.lado_agindo(state) != lado_humano:
		await get_tree().create_timer(0.55).timeout
		if not is_inside_tree():
			return
		var lado := MatchRunner.lado_agindo(state)
		var acao: Dictionary = ia.escolher(db, state, lado)
		if acao.is_empty() or not Rules.aplicar(db, state, acao):
			Rules.aplicar(db, state, {"tipo": "encerrar_turno"})
		_render()
	_ia_agindo = false
	_apos_mudanca()


## XP e progresso de missões ao fim de cada batalha.
func _registrar_metajogo(venceu: bool) -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	Missions.atualizar_dia(Save.dados, Time.get_date_string_from_system(), rng)
	if venceu:
		Missions.registrar_evento(Save.dados, "vencer_batalhas")
		if Ctx.batalha.get("campanha", false):
			Missions.registrar_evento(Save.dados, "vencer_campanha")
	Missions.registrar_evento(Save.dados, "causar_dano",
			int(Rules.jogador(state, lado_humano)["dano_causado"]))
	Progression.registrar_batalha(Save.dados, venceu)
	Save.salvar()


func _mostrar_fim() -> void:
	if _fim_notificado:
		return
	_fim_notificado = true
	var venceu := int(state["vencedor"]) == lado_humano
	var empate := int(state["vencedor"]) == 2

	_overlay_fim = PanelContainer.new()
	_overlay_fim.set_anchors_preset(Control.PRESET_CENTER)
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color("1a1440ee")
	estilo.corner_radius_top_left = 20
	estilo.corner_radius_top_right = 20
	estilo.corner_radius_bottom_left = 20
	estilo.corner_radius_bottom_right = 20
	estilo.content_margin_left = 60
	estilo.content_margin_right = 60
	estilo.content_margin_top = 40
	estilo.content_margin_bottom = 40
	_overlay_fim.add_theme_stylebox_override("panel", estilo)
	add_child(_overlay_fim)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 24)
	_overlay_fim.add_child(v)
	var titulo := _novo_label(64)
	titulo.text = "EMPATE" if empate else ("VITÓRIA!" if venceu else "DERROTA")
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(titulo)
	var placar := _novo_label(32)
	placar.text = "Selos: você %d × %d oponente" % [
		Rules.jogador(state, lado_humano)["selos"], Rules.jogador(state, 1 - lado_humano)["selos"]]
	placar.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(placar)
	var btn := Button.new()
	btn.text = "Continuar"
	btn.add_theme_font_size_override("font_size", 32)
	btn.pressed.connect(func():
		_registrar_metajogo(venceu)
		batalha_terminou.emit(venceu, state)
		if Ctx.batalha.get("campanha", false):
			# A trilha da campanha processa o resultado ao ser recarregada.
			Ctx.resultado = {
				"venceu": venceu,
				"turnos": int(state["turno"]),
				"selos_oponente": int(Rules.jogador(state, 1 - lado_humano)["selos"]),
			}
			get_tree().change_scene_to_file("res://game/campaign/trail.tscn")
		elif batalha_terminou.get_connections().is_empty():
			get_tree().change_scene_to_file("res://game/home/home.tscn"))
	v.add_child(btn)
