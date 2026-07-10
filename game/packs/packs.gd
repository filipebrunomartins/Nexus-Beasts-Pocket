extends ScreenBase
## Loja de Pacotes: timer de 12h, ampulhetas e abertura com reveal
## carta a carta (a animação de "rasgar" chega no polimento).

var db: CardDB
var _lbl_timer: Label
var _btn_abrir: Button
var _btn_ampulheta: Button
var _btn_bonus: Button
var _btn_comprar: Button
var _area_reveal: VBoxContainer
var _cartas_pendentes: Array = []


func _ready() -> void:
	db = CardDB.load_default()
	montar_base("Loja de Pacotes")

	var pacote := PanelContainer.new()
	pacote.custom_minimum_size = Vector2(0, 220)
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color("#3b1d6e")
	estilo.border_color = Color("#c86bff")
	for b in ["border_width_left", "border_width_right", "border_width_top", "border_width_bottom"]:
		estilo.set(b, 4)
	for c in ["corner_radius_top_left", "corner_radius_top_right", "corner_radius_bottom_left", "corner_radius_bottom_right"]:
		estilo.set(c, 18)
	pacote.add_theme_stylebox_override("panel", estilo)
	var pv := VBoxContainer.new()
	pv.alignment = BoxContainer.ALIGNMENT_CENTER
	pacote.add_child(pv)
	var nome_set := label("🎴 DESPERTAR DO NEXUS", 40)
	nome_set.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pv.add_child(nome_set)
	var sub := label("5 cartas por pacote • 1 pacote grátis a cada 12h", 22, Color("#d1c4e9"))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pv.add_child(sub)
	conteudo.add_child(pacote)

	_lbl_timer = label("", 28)
	_lbl_timer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	conteudo.add_child(_lbl_timer)

	var botoes := HBoxContainer.new()
	botoes.alignment = BoxContainer.ALIGNMENT_CENTER
	botoes.add_theme_constant_override("separation", 16)
	conteudo.add_child(botoes)
	_btn_abrir = botao("Abrir pacote!", _abrir_pacote, 34)
	_btn_abrir.custom_minimum_size = Vector2(360, 90)
	botoes.add_child(_btn_abrir)
	_btn_ampulheta = botao("⏳ Usar ampulheta (−1h)", _usar_ampulheta, 26)
	botoes.add_child(_btn_ampulheta)
	_btn_bonus = botao("", _abrir_bonus, 26)
	botoes.add_child(_btn_bonus)
	_btn_comprar = botao("", _comprar_com_moedas, 26)
	botoes.add_child(_btn_comprar)

	_area_reveal = VBoxContainer.new()
	_area_reveal.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_area_reveal.alignment = BoxContainer.ALIGNMENT_CENTER
	conteudo.add_child(_area_reveal)

	var probs := label("Probabilidades:\n" + PackSystem.tabela_probabilidades(), 18, Color("#90a4ae"))
	conteudo.add_child(probs)

	_atualizar()


func _process(_delta: float) -> void:
	if Engine.get_frames_drawn() % 30 == 0:
		_atualizar()


func _atualizar() -> void:
	var agora := int(Time.get_unix_time_from_system())
	if PackSystem.pode_abrir(Save.dados, agora):
		_lbl_timer.text = "🎁 Pacote disponível!"
		_btn_abrir.disabled = false
		_btn_ampulheta.visible = false
	else:
		var seg := PackSystem.segundos_restantes(Save.dados, agora)
		@warning_ignore("integer_division")
		_lbl_timer.text = "Próximo pacote em %dh%02dm%02ds" % [seg / 3600, (seg % 3600) / 60, seg % 60]
		_btn_abrir.disabled = true
		_btn_ampulheta.visible = true
		_btn_ampulheta.text = "⏳ Usar ampulheta (−1h) — tem %d" % Save.dados["ampulhetas"]
		_btn_ampulheta.disabled = int(Save.dados["ampulhetas"]) <= 0
	var bonus := int(Save.dados.get("pacotes_bonus", 0))
	_btn_bonus.visible = bonus > 0
	_btn_bonus.text = "🎁 Abrir pacote bônus (×%d)" % bonus
	_btn_comprar.text = "💰 Comprar pacote (%d moedas)" % PRECO_PACOTE_MOEDAS
	_btn_comprar.disabled = int(Save.dados["moedas"]) < PRECO_PACOTE_MOEDAS


func _usar_ampulheta() -> void:
	if PackSystem.usar_ampulheta(Save.dados):
		Save.salvar()
	_atualizar()


func _abrir_pacote() -> void:
	var agora := int(Time.get_unix_time_from_system())
	if not PackSystem.pode_abrir(Save.dados, agora):
		return
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	_cartas_pendentes = PackSystem.abrir(db, Save.dados, agora, rng)
	Missions.registrar_evento(Save.dados, "abrir_pacotes")
	Save.adicionar_cartas(_cartas_pendentes)
	_btn_abrir.disabled = true
	_revelar_proxima()


## Pacote comprado com moedas (economia leve — só acelera a coleção).
const PRECO_PACOTE_MOEDAS := 150

func _comprar_com_moedas() -> void:
	if int(Save.dados["moedas"]) < PRECO_PACOTE_MOEDAS:
		return
	Save.dados["moedas"] = int(Save.dados["moedas"]) - PRECO_PACOTE_MOEDAS
	Save.dados["pacotes_bonus"] = int(Save.dados.get("pacotes_bonus", 0)) + 1
	Save.salvar()
	_atualizar()


## Pacote bônus (recompensa de campanha): abre sem consumir o timer.
func _abrir_bonus() -> void:
	if int(Save.dados.get("pacotes_bonus", 0)) <= 0:
		return
	Save.dados["pacotes_bonus"] = int(Save.dados["pacotes_bonus"]) - 1
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var timer_anterior := int(Save.dados["prox_pacote_ts"])
	_cartas_pendentes = PackSystem.abrir(db, Save.dados, int(Time.get_unix_time_from_system()), rng)
	Save.dados["prox_pacote_ts"] = timer_anterior  # bônus não mexe no timer
	Missions.registrar_evento(Save.dados, "abrir_pacotes")
	Save.adicionar_cartas(_cartas_pendentes)
	_revelar_proxima()


## Reveal uma a uma: mostra a carta grande; toque revela a próxima.
func _revelar_proxima() -> void:
	for filho in _area_reveal.get_children():
		filho.queue_free()
	if _cartas_pendentes.is_empty():
		_atualizar()
		return
	var id: String = _cartas_pendentes.pop_front()
	var restam := _cartas_pendentes.size()
	Sfx.tocar("reveal")

	var centro := CenterContainer.new()
	centro.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_area_reveal.add_child(centro)
	var carta := CardRenderer.nova(db, id)
	carta.scale = Vector2(0.1, 0.1)
	carta.pivot_offset = Vector2(CardRenderer.LARGURA, CardRenderer.ALTURA) / 2.0
	centro.add_child(carta)
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(carta, "scale", Vector2.ONE * 0.72, 0.45)

	var dica := label("Toque para %s" % ("revelar a próxima (%d)" % restam if restam > 0 else "terminar"), 24, Color("#b0bec5"))
	dica.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_area_reveal.add_child(dica)

	carta.gui_input.connect(func(ev):
		if ev is InputEventMouseButton and ev.pressed:
			_revelar_proxima())
	centro.gui_input.connect(func(ev):
		if ev is InputEventMouseButton and ev.pressed:
			_revelar_proxima())
