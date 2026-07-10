extends ScreenBase
## HOME — hub de navegação (mapa de telas 7.2).

var db: CardDB


func _ready() -> void:
	db = CardDB.load_default()
	montar_base("NEXUS BEASTS", false)

	var status := label("", 24, Color("#b0bec5"))
	var agora := int(Time.get_unix_time_from_system())
	var pacote_txt := "pronto!" if PackSystem.pode_abrir(Save.dados, agora) else _fmt_tempo(PackSystem.segundos_restantes(Save.dados, agora))
	status.text = "💰 %d moedas   ⏳ %d ampulhetas   🎁 pacote: %s   📚 %d/79 cartas" % [
		Save.dados["moedas"], Save.dados["ampulhetas"], pacote_txt, Save.total_cartas_unicas()]
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	conteudo.add_child(status)

	var meio := VBoxContainer.new()
	meio.add_theme_constant_override("separation", 20)
	meio.size_flags_vertical = Control.SIZE_EXPAND_FILL
	meio.alignment = BoxContainer.ALIGNMENT_CENTER
	conteudo.add_child(meio)

	for cfg in [
		["🗺  CAMPANHA", "res://game/campaign/map_select.tscn"],
		["⚔  Batalha Livre", "res://game/battle/battle.tscn"],
		["🎁  Loja de Pacotes", "res://game/packs/packs.tscn"],
		["📚  Coleção", "res://game/collection/collection.tscn"],
		["🃏  Baralhos", "res://game/deck_editor/deck_list.tscn"],
		["🎯  Missões", "res://game/missions/missions.tscn"],
	]:
		var caminho: String = cfg[1]
		var b := botao(cfg[0], func(): get_tree().change_scene_to_file(caminho), 38)
		b.custom_minimum_size = Vector2(0, 96)
		if not ResourceLoader.exists(caminho):
			b.disabled = true
			b.text += "  (em breve)"
		meio.add_child(b)


func _fmt_tempo(seg: int) -> String:
	@warning_ignore("integer_division")
	return "%dh%02dm" % [seg / 3600, (seg % 3600) / 60]
