extends NBTest
## Testes de missões diárias, progressão de conta e marcos de estrelas.


func _perfil() -> Dictionary:
	return {
		"moedas": 0, "ampulhetas": 0, "xp": 0, "pacotes_bonus": 0,
		"missoes": {"dia": "", "lista": []},
		"campanha": {"vencidos": {}, "estrelas": {}},
	}


func _rng(semente: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = semente
	return r


func test_sorteio_diario() -> void:
	var perfil := _perfil()
	Missions.atualizar_dia(perfil, "2026-07-10", _rng(1))
	igual((perfil["missoes"]["lista"] as Array).size(), 3, "3 missões por dia")
	var lista_antes: Array = perfil["missoes"]["lista"]
	Missions.atualizar_dia(perfil, "2026-07-10", _rng(2))
	ok(perfil["missoes"]["lista"] == lista_antes, "mesmo dia não re-sorteia")
	Missions.atualizar_dia(perfil, "2026-07-11", _rng(3))
	igual(perfil["missoes"]["dia"], "2026-07-11", "novo dia re-sorteia")


func test_progresso_e_resgate() -> void:
	var perfil := _perfil()
	perfil["missoes"] = {"dia": "2026-07-10", "lista": [
		{"tipo": "vencer_batalhas", "alvo": 2, "texto": "t", "recompensa": {"moedas": 80}, "progresso": 0, "resgatada": false},
	]}
	Missions.registrar_evento(perfil, "vencer_batalhas")
	igual(perfil["missoes"]["lista"][0]["progresso"], 1, "progresso avança")
	ok(Missions.resgatar(perfil, 0).is_empty(), "incompleta não resgata")
	Missions.registrar_evento(perfil, "vencer_batalhas")
	Missions.registrar_evento(perfil, "vencer_batalhas")
	igual(perfil["missoes"]["lista"][0]["progresso"], 2, "progresso trava no alvo")
	var ganhos := Missions.resgatar(perfil, 0)
	ok(not ganhos.is_empty(), "resgate paga")
	igual(perfil["moedas"], 80, "moedas creditadas")
	igual(perfil["xp"], Missions.XP_POR_MISSAO, "XP da missão")
	ok(Missions.resgatar(perfil, 0).is_empty(), "não resgata duas vezes")


func test_progresso_dano() -> void:
	var perfil := _perfil()
	perfil["missoes"] = {"dia": "d", "lista": [
		{"tipo": "causar_dano", "alvo": 200, "texto": "t", "recompensa": {"ampulhetas": 1}, "progresso": 0, "resgatada": false},
	]}
	Missions.registrar_evento(perfil, "causar_dano", 130)
	Missions.registrar_evento(perfil, "causar_dano", 130)
	ok(Missions.completa(perfil["missoes"]["lista"][0]), "dano acumula entre batalhas")


func test_niveis_de_conta() -> void:
	igual(Progression.nivel_de(0), 1, "começa no nível 1")
	igual(Progression.nivel_de(99), 1, "99 XP ainda nível 1")
	igual(Progression.nivel_de(100), 2, "100 XP = nível 2")
	igual(Progression.nivel_de(250), 3, "100+150 XP = nível 3")
	var perfil := _perfil()
	perfil["xp"] = 90
	var ganhos := Progression.ganhar_xp(perfil, 20)
	ok(ganhos.size() >= 2, "subida de nível anunciada")
	igual(perfil["moedas"], Progression.MOEDAS_POR_NIVEL, "bônus de nível pago")


func test_dano_causado_no_motor() -> void:
	var state := cenario("NB-007", "NB-013")  # Gotari: sem fraqueza a Brasa
	energizar(state["jogadores"][0]["ativo"], ["brasa"])
	agir(state, {"tipo": "atacar"})
	igual(state["jogadores"][0]["dano_causado"], 20, "motor contabiliza dano causado")


func test_marcos_de_estrelas() -> void:
	var mapas := Campaign.carregar()
	var perfil := _perfil()
	var mapa: Dictionary = mapas[0]
	# 2 desafiantes com 3 estrelas = 6★ → 1 pacote
	perfil["campanha"]["estrelas"]["m1_d1"] = 3
	perfil["campanha"]["estrelas"]["m1_d2"] = 3
	igual(Campaign.resgatar_marcos(perfil, mapa), 1, "6★ libera 1 pacote")
	igual(perfil["pacotes_bonus"], 1, "pacote creditado")
	igual(Campaign.resgatar_marcos(perfil, mapa), 0, "marco não repete")
	for i in 6:
		perfil["campanha"]["estrelas"]["m1_d%d" % (i + 1)] = 3
	igual(Campaign.resgatar_marcos(perfil, mapa), 2, "12★ e 18★ liberam os outros 2")
