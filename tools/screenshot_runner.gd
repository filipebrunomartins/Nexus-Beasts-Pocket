extends Node
## Abre uma cena, espera e salva screenshots — para inspeção visual durante o
## desenvolvimento. Uso:
##   NBP_CENA=res://game/battle/battle.tscn NBP_SHOT=/tmp/shot godot tools/screenshot_runner.tscn
## Salva NBP_SHOT_1.png, _2.png... a cada NBP_INTERVALO segundos (padrão 2s, 3 shots).


func _ready() -> void:
	var cena := OS.get_environment("NBP_CENA")
	if cena == "":
		cena = "res://game/battle/battle.tscn"
	var destino := OS.get_environment("NBP_SHOT")
	if destino == "":
		destino = "user://shot"
	var qtd := maxi(int(OS.get_environment("NBP_QTD")), 1) if OS.get_environment("NBP_QTD") != "" else 3
	var intervalo := 2.0

	# Preparação de contexto para telas que exigem
	if OS.get_environment("NBP_CAMPANHA") != "":
		# configura a batalha como a trilha faria, para o desafiante dado
		var did := OS.get_environment("NBP_CAMPANHA")
		var db := CardDB.load_default()
		for mapa in Campaign.carregar():
			for des in mapa["desafiantes"]:
				if des["id"] == did and des.has("deck"):
					Ctx.batalha = {
						"campanha": true, "desafiante_id": did,
						"deck_ia": des["deck"],
						"tipos_ia": Rules.sugerir_tipos_mana(db, des["deck"]),
						"nivel_ia": int(mapa["nivel_ia"]),
						"nome_oponente": des["nome"],
						"regras": des.get("regras", []), "fase_dupla": 1,
					}
	if OS.get_environment("NBP_DECK_EDIT") == "1":
		var decks: Array = Save.dados["decks"]
		Ctx.deck_em_edicao = decks.size()
		decks.append({"nome": "Deck de teste", "cartas": (decks[0]["cartas"] as Array).slice(0, 12), "emprestado": false})

	var inst: Node = load(cena).instantiate()
	add_child(inst)
	var auto := OS.get_environment("NBP_AUTO") == "1"
	var piloto := HeuristicAI.new(2, 777)
	for i in qtd:
		var espera := 0.0
		while espera < intervalo:
			await get_tree().create_timer(0.3).timeout
			espera += 0.3
			# Auto-play: joga pelo lado humano da batalha (para inspeção visual)
			if auto and "state" in inst and inst.state["fase"] != "fim" \
					and MatchRunner.lado_agindo(inst.state) == inst.lado_humano:
				var acao: Dictionary = piloto.escolher(inst.db, inst.state, inst.lado_humano)
				if not acao.is_empty():
					inst._ao_escolher_acao(acao)
		var img := get_viewport().get_texture().get_image()
		img.save_png("%s_%d.png" % [destino, i + 1])
		print("screenshot salvo: %s_%d.png" % [destino, i + 1])
	get_tree().quit()
