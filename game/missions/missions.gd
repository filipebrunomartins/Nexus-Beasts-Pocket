extends ScreenBase
## Missões diárias: progresso e resgate de recompensas.

var _lista_box: VBoxContainer


func _ready() -> void:
	montar_base("Missões Diárias")
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	Missions.atualizar_dia(Save.dados, Time.get_date_string_from_system(), rng)
	Save.salvar()

	var nivel := Progression.nivel_de(int(Save.dados["xp"]))
	var prox := Progression.xp_para_nivel(nivel + 1)
	var info := label("Nível %d  •  XP %d/%d" % [nivel, Save.dados["xp"], prox], 26, Color("#b0bec5"))
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	conteudo.add_child(info)

	_lista_box = VBoxContainer.new()
	_lista_box.add_theme_constant_override("separation", 14)
	_lista_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	conteudo.add_child(_lista_box)
	_popular()


func _popular() -> void:
	for filho in _lista_box.get_children():
		filho.queue_free()
	var lista: Array = Save.dados["missoes"].get("lista", [])
	for i in lista.size():
		_lista_box.add_child(_painel_missao(i, lista[i]))


func _painel_missao(idx: int, m: Dictionary) -> Control:
	var painel := PanelContainer.new()
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color("#26224a") if not m["resgatada"] else Color("#1c2a1c")
	estilo.border_color = Color("#5c6bc0") if not m["resgatada"] else Color("#4caf50")
	for b in ["border_width_left", "border_width_right", "border_width_top", "border_width_bottom"]:
		estilo.set(b, 3)
	for c in ["corner_radius_top_left", "corner_radius_top_right", "corner_radius_bottom_left", "corner_radius_bottom_right"]:
		estilo.set(c, 14)
	for mg in ["content_margin_left", "content_margin_right", "content_margin_top", "content_margin_bottom"]:
		estilo.set(mg, 16)
	painel.add_theme_stylebox_override("panel", estilo)

	var v := VBoxContainer.new()
	painel.add_child(v)
	v.add_child(label(m["texto"], 28))

	var barra := ProgressBar.new()
	barra.max_value = int(m["alvo"])
	barra.value = int(m["progresso"])
	barra.custom_minimum_size = Vector2(0, 30)
	v.add_child(barra)

	var r: Dictionary = m["recompensa"]
	var recompensa_txt: PackedStringArray = []
	if r.has("moedas"): recompensa_txt.append("💰%d" % r["moedas"])
	if r.has("ampulhetas"): recompensa_txt.append("⏳%d" % r["ampulhetas"])
	recompensa_txt.append("✨%d XP" % Missions.XP_POR_MISSAO)

	var rodape := HBoxContainer.new()
	v.add_child(rodape)
	rodape.add_child(label("%d/%d  •  %s" % [m["progresso"], m["alvo"], " ".join(recompensa_txt)], 22, Color("#ffe082")))
	var espaco := Control.new()
	espaco.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rodape.add_child(espaco)
	if m["resgatada"]:
		rodape.add_child(label("✓ resgatada", 22, Color("#a5d6a7")))
	elif Missions.completa(m):
		rodape.add_child(botao("Resgatar!", func():
			Missions.resgatar(Save.dados, idx)
			Save.salvar()
			_popular(), 24))
	return painel
