extends NBTest
## Testes da campanha: dados, progressão, estrelas e recompensas.


func _perfil() -> Dictionary:
	return {
		"moedas": 0, "ampulhetas": 0, "pacotes_bonus": 0,
		"colecao": {}, "titulos": [],
		"campanha": {"vencidos": {}, "estrelas": {}},
	}


func test_estrutura_dos_mapas() -> void:
	var mapas := Campaign.carregar()
	igual(mapas.size(), 4, "4 mapas")
	for mapa in mapas:
		igual((mapa["desafiantes"] as Array).size(), 6, "%s tem 6 desafiantes" % mapa["nome"])
		ok(mapa["desafiantes"][-1].get("guardiao", false), "%s: 6º é guardião" % mapa["nome"])
		ok(int(mapa["nivel_ia"]) >= 1 and int(mapa["nivel_ia"]) <= 4, "nível de IA 1–4")


func test_decks_dos_desafiantes_validos() -> void:
	for mapa in Campaign.carregar():
		for des in mapa["desafiantes"]:
			var decks_para_checar: Array = []
			if des.has("deck"):
				decks_para_checar.append(des["deck"])
			if des.has("deck2"):
				decks_para_checar.append(des["deck2"])
			for d in des.get("decks_sorteio", []):
				decks_para_checar.append(d)
			if (des.get("regras", []) as Array).has("espelho"):
				ok(decks_para_checar.is_empty(), "%s: espelho não precisa de deck" % des["nome"])
				continue
			ok(not decks_para_checar.is_empty(), "%s: tem deck" % des["nome"])
			for deck in decks_para_checar:
				var erros := Rules.validar_deck(db, deck)
				ok(erros.is_empty(), "%s: deck válido (%s)" % [des["nome"], erros[0] if not erros.is_empty() else ""])


func test_omega_apenas_do_mapa_2_em_diante() -> void:
	var mapas := Campaign.carregar()
	for des in mapas[0]["desafiantes"]:
		for id in des.get("deck", []):
			ok(not db.get_card(id).get("omega", false), "Mapa 1 sem cartas Ω (%s)" % des["nome"])


func test_desbloqueio_sequencial() -> void:
	var mapas := Campaign.carregar()
	var perfil := _perfil()
	ok(Campaign.mapa_desbloqueado(perfil, mapas, 0), "mapa 1 aberto")
	ok(not Campaign.mapa_desbloqueado(perfil, mapas, 1), "mapa 2 fechado")
	ok(Campaign.desafiante_desbloqueado(perfil, mapas[0], 0), "1º desafiante aberto")
	ok(not Campaign.desafiante_desbloqueado(perfil, mapas[0], 1), "2º fechado")
	perfil["campanha"]["vencidos"]["m1_d1"] = true
	ok(Campaign.desafiante_desbloqueado(perfil, mapas[0], 1), "2º abre após vencer o 1º")
	perfil["campanha"]["vencidos"]["m1_d6"] = true
	ok(Campaign.mapa_desbloqueado(perfil, mapas, 1), "mapa 2 abre após o guardião")


func test_estrelas_de_desempenho() -> void:
	igual(Campaign.calcular_estrelas(false, 0, 5), 0, "derrota = 0")
	igual(Campaign.calcular_estrelas(true, 2, 20), 1, "vitória simples = 1")
	igual(Campaign.calcular_estrelas(true, 0, 20), 2, "sem perder besta = 2")
	igual(Campaign.calcular_estrelas(true, 0, 12), 3, "rápida e limpa = 3")


func test_recompensas_primeira_vitoria_e_revanche() -> void:
	var mapas := Campaign.carregar()
	var perfil := _perfil()
	var aurora: Dictionary = mapas[0]["desafiantes"][5]  # carta promocional Selvarok
	var ganhos := Campaign.registrar_resultado(perfil, aurora, true, 0, 10)
	ok(ganhos.size() >= 2, "primeira vitória dá recompensas")
	igual(perfil["moedas"], 100, "moedas creditadas")
	igual(int(perfil["colecao"].get("NB-003", 0)), 1, "carta promocional na coleção")
	igual(Campaign.estrelas(perfil, aurora["id"]), 3, "3 estrelas registradas")

	var ganhos2 := Campaign.registrar_resultado(perfil, aurora, true, 2, 20)
	igual(perfil["moedas"], 120, "revanche dá só 20 moedas")
	igual(int(perfil["colecao"].get("NB-003", 0)), 1, "carta não duplica")
	igual(Campaign.estrelas(perfil, aurora["id"]), 3, "estrelas não regridem")
	ok(ganhos2.size() >= 1, "revanche informa ganhos")


func test_derrota_nao_registra() -> void:
	var mapas := Campaign.carregar()
	var perfil := _perfil()
	Campaign.registrar_resultado(perfil, mapas[0]["desafiantes"][0], false, 3, 8)
	ok(not Campaign.venceu(perfil, "m1_d1"), "derrota não marca vitória")
	igual(perfil["moedas"], 0, "derrota não paga")


func test_dano_ao_entrar_gemeos() -> void:
	var decks := CardDB.load_decks()
	var state := Rules.nova_partida(db, decks[0]["cartas"], decks[1]["cartas"],
			decks[0]["tipos_mana"], decks[1]["tipos_mana"], 5, 0)
	state["modificadores"] = {"dano_ao_entrar": {0: 10}}
	while state["fase"] == "setup":
		Rules.aplicar(db, state, Rules.acoes_legais(db, state)[0])
	igual(state["jogadores"][0]["ativo"]["dano"], 10, "besta do lado 0 entra com 10 de dano")
	igual(state["jogadores"][1]["ativo"]["dano"], 0, "lado 1 entra intacto")
