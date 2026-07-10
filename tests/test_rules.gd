extends NBTest
## Testes do motor de regras — cada regra da Parte 1 do design.

# ------------------------------------------------ setup e turnos

func test_setup_inicial() -> void:
	var decks := CardDB.load_decks()
	var state := Rules.nova_partida(db, decks[0]["cartas"], decks[1]["cartas"], ["brasa"], ["mare"], 7, 0)
	igual(state["fase"], "setup", "fase inicial")
	for lado in 2:
		var p: Dictionary = state["jogadores"][lado]
		igual((p["mao"] as Array).size(), Rules.MAO_INICIAL, "mão inicial de 5")
		igual((p["deck"] as Array).size(), Rules.TAMANHO_DECK - Rules.MAO_INICIAL, "deck com 15")
		var tem_basico := false
		for id in p["mao"]:
			if CardDB.is_basic_beast(db.get_card(id)):
				tem_basico = true
		ok(tem_basico, "mão inicial garante 1 básico (lado %d)" % lado)


func test_primeiro_turno_sem_mana() -> void:
	var state := partida()
	igual(state["jogador_atual"], 0, "jogador 0 começa")
	igual(state["turno"], 1, "turno 1")
	igual(state["jogadores"][0]["mana_atual"], "", "quem começa não recebe mana no 1º turno")
	agir(state, {"tipo": "encerrar_turno"})
	igual(state["jogador_atual"], 1, "vez do jogador 1")
	ok(state["jogadores"][1]["mana_atual"] != "", "jogador 1 recebe mana no seu 1º turno")


func test_compra_e_limite_de_mao() -> void:
	var state := partida()
	# Jogador 0 comprou 1 no início do turno: 5 - 1 (ativo) + 1 = 5
	igual((state["jogadores"][0]["mao"] as Array).size(), 5, "compra do turno 1")
	# Mão cheia (10): não compra
	var p1: Dictionary = state["jogadores"][1]
	while (p1["mao"] as Array).size() < Rules.LIMITE_MAO:
		p1["mao"].append("AL-009")
	var deck_antes := (p1["deck"] as Array).size()
	agir(state, {"tipo": "encerrar_turno"})
	igual((p1["mao"] as Array).size(), Rules.LIMITE_MAO, "mão não passa de 10")
	igual((p1["deck"] as Array).size(), deck_antes, "não comprou com mão cheia")


func test_deck_vazio_nao_derrota() -> void:
	var state := cenario("NB-007", "NB-013")
	state["jogadores"][1]["deck"] = []
	agir(state, {"tipo": "encerrar_turno"})
	igual(state["fase"], "jogando", "ficar sem deck não encerra a partida")


func test_empate_no_turno_limite() -> void:
	var state := cenario("NB-007", "NB-013")
	state["turno"] = Rules.TURNO_EMPATE
	agir(state, {"tipo": "encerrar_turno"})
	igual(state["fase"], "fim", "partida termina no limite de turnos")
	igual(state["vencedor"], 2, "empate")


func test_anexar_mana_uma_vez() -> void:
	var state := cenario("NB-007", "NB-013")
	state["jogadores"][0]["mana_atual"] = "brasa"
	agir(state, {"tipo": "anexar_mana"})
	igual((state["jogadores"][0]["ativo"]["energias"] as Array).size(), 1, "energia anexada")
	ok(not tem_acao(state, {"tipo": "anexar_mana"}), "só 1 mana por turno")


func test_mana_nao_usada_se_perde() -> void:
	var state := cenario("NB-007", "NB-013")
	state["jogadores"][0]["mana_atual"] = "brasa"
	agir(state, {"tipo": "encerrar_turno"})
	igual(state["jogadores"][0]["mana_atual"], "", "mana não usada é descartada")

# ------------------------------------------------ evolução

func test_evolucao_regras() -> void:
	var state := cenario("NB-007", "NB-013")  # Fagulho ativo
	var p0: Dictionary = state["jogadores"][0]
	p0["mao"] = ["NB-008"]  # Pirandra

	# Não evolui besta que entrou neste turno
	p0["ativo"]["entrou_no_turno"] = state["turno"]
	ok(not tem_acao(state, {"tipo": "evoluir"}), "não evolui no turno em que entrou")

	# Ok no turno seguinte
	p0["ativo"]["entrou_no_turno"] = state["turno"] - 1
	Rules.aplicar_status(state, p0["ativo"], "envenenado")
	agir(state, {"tipo": "evoluir"})
	igual(p0["ativo"]["carta"], "NB-008", "evoluiu para Pirandra")
	igual((p0["ativo"]["status"] as Array).size(), 0, "evoluir cura condições")
	igual((p0["mao"] as Array).size(), 0, "carta saiu da mão")

	# Só 1 evolução por monstro por turno
	p0["mao"] = ["NB-009"]  # Vulkragon
	ok(not tem_acao(state, {"tipo": "evoluir"}), "não evolui 2x no mesmo turno")


func test_sem_evolucao_no_primeiro_turno() -> void:
	var state := cenario("NB-007", "NB-013")
	state["turno"] = 1
	var p0: Dictionary = state["jogadores"][0]
	p0["mao"] = ["NB-008"]
	p0["ativo"]["entrou_no_turno"] = 0
	ok(not tem_acao(state, {"tipo": "evoluir"}), "sem evolução no 1º turno de cada jogador")

# ------------------------------------------------ reserva

func test_reserva_limite_3() -> void:
	var state := cenario("NB-007", "NB-013")
	var p0: Dictionary = state["jogadores"][0]
	p0["mao"] = ["NB-010", "NB-010", "NB-011", "NB-011"]
	for i in 3:
		agir(state, {"tipo": "colocar_reserva"})
	igual((p0["reserva"] as Array).size(), 3, "3 na reserva")
	ok(not tem_acao(state, {"tipo": "colocar_reserva"}), "reserva máxima de 3")

# ------------------------------------------------ ataque, custo e fraqueza

func test_ataque_exige_energia() -> void:
	var state := cenario("NB-007", "NB-013")
	ok(not tem_acao(state, {"tipo": "atacar"}), "sem energia não ataca")
	energizar(state["jogadores"][0]["ativo"], ["brasa"])
	ok(tem_acao(state, {"tipo": "atacar"}), "com energia ataca")


func test_custo_qualquer_aceita_todo_tipo() -> void:
	var state := cenario("NB-023", "NB-013")  # Magnetauro: ⚡⚡⭐
	energizar(state["jogadores"][0]["ativo"], ["faisca", "faisca", "sombra"])
	ok(tem_acao(state, {"tipo": "atacar"}), "⭐ pago com qualquer energia")


func test_custo_tipado_nao_substituivel() -> void:
	var state := cenario("NB-007", "NB-013")  # Fagulho: 🔥
	energizar(state["jogadores"][0]["ativo"], ["mare"])
	ok(not tem_acao(state, {"tipo": "atacar"}), "custo 🔥 não aceita 💧")


func test_fraqueza_20() -> void:
	var state := cenario("NB-007", "NB-001")  # Brasa ataca Flora (fraqueza brasa)
	energizar(state["jogadores"][0]["ativo"], ["brasa"])
	agir(state, {"tipo": "atacar"})
	igual(state["jogadores"][1]["ativo"]["dano"], 40, "20 base + 20 fraqueza")


func test_sem_fraqueza_dano_normal() -> void:
	var state := cenario("NB-013", "NB-001")  # Maré ataca Flora (sem fraqueza)
	energizar(state["jogadores"][0]["ativo"], ["mare"])
	agir(state, {"tipo": "atacar"})
	igual(state["jogadores"][1]["ativo"]["dano"], 20, "dano sem modificador")


func test_energia_nao_gasta_ao_atacar() -> void:
	var state := cenario("NB-007", "NB-016")
	energizar(state["jogadores"][0]["ativo"], ["brasa"])
	agir(state, {"tipo": "atacar"})
	igual((state["jogadores"][0]["ativo"]["energias"] as Array).size(), 1, "energia permanece após atacar")


func test_atacar_encerra_turno() -> void:
	var state := cenario("NB-007", "NB-016")
	energizar(state["jogadores"][0]["ativo"], ["brasa"])
	agir(state, {"tipo": "atacar"})
	igual(state["jogador_atual"], 1, "ataque encerra o turno")

# ------------------------------------------------ nocaute, selos e vitória

func test_nocaute_da_selo_e_promocao() -> void:
	var state := cenario("NB-007", "NB-013")
	reservar(state, 1, "NB-017")
	state["jogadores"][1]["ativo"]["dano"] = 50  # Gotari 60 PS
	energizar(state["jogadores"][0]["ativo"], ["brasa"])
	agir(state, {"tipo": "atacar"})
	igual(state["jogadores"][0]["selos"], 1, "nocaute comum = 1 selo")
	igual(state["fase"], "promocao", "aguarda promoção")
	agir(state, {"tipo": "promover"})
	ok(state["jogadores"][1]["ativo"] != null, "promovido da reserva")
	igual(state["jogador_atual"], 1, "turno passou após promoção")


func test_nocaute_omega_da_2_selos() -> void:
	var state := cenario("NB-007", "NB-012")  # Vulkragon Ω 140 PS
	reservar(state, 1, "NB-013")
	state["jogadores"][1]["ativo"]["dano"] = 130
	energizar(state["jogadores"][0]["ativo"], ["brasa"])
	agir(state, {"tipo": "atacar"})
	igual(state["jogadores"][0]["selos"], 2, "nocaute Ω = 2 selos")


func test_vitoria_3_selos() -> void:
	var state := cenario("NB-007", "NB-013")
	reservar(state, 1, "NB-017")
	state["jogadores"][0]["selos"] = 2
	state["jogadores"][1]["ativo"]["dano"] = 50
	energizar(state["jogadores"][0]["ativo"], ["brasa"])
	agir(state, {"tipo": "atacar"})
	igual(state["fase"], "fim", "partida encerrada")
	igual(state["vencedor"], 0, "3 selos vencem")


func test_vitoria_sem_monstros() -> void:
	var state := cenario("NB-007", "NB-013")  # oponente sem reserva
	state["jogadores"][1]["ativo"]["dano"] = 50
	energizar(state["jogadores"][0]["ativo"], ["brasa"])
	agir(state, {"tipo": "atacar"})
	igual(state["vencedor"], 0, "oponente sem monstros perde")

# ------------------------------------------------ recuo

func test_recuo_paga_custo() -> void:
	var state := cenario("NB-011", "NB-013")  # Lavaboi recuo 3
	reservar(state, 0, "NB-007")
	ok(not tem_acao(state, {"tipo": "recuar"}), "sem energia não recua")
	energizar(state["jogadores"][0]["ativo"], ["brasa", "brasa", "brasa"])
	agir(state, {"tipo": "recuar"})
	var p0: Dictionary = state["jogadores"][0]
	igual(p0["ativo"]["carta"], "NB-007", "reserva assumiu")
	igual((p0["reserva"][0]["energias"] as Array).size(), 0, "custo de recuo descartado")
	ok(not tem_acao(state, {"tipo": "recuar"}), "só 1 recuo por turno")


func test_recuo_cura_status() -> void:
	var state := cenario("NB-022", "NB-013")  # Zumbizz recuo 0
	reservar(state, 0, "NB-007")
	Rules.aplicar_status(state, state["jogadores"][0]["ativo"], "envenenado")
	agir(state, {"tipo": "recuar"})
	igual((state["jogadores"][0]["reserva"][0]["status"] as Array).size(), 0, "ir ao banco cura condições")

# ------------------------------------------------ condições especiais

func test_veneno_checkup() -> void:
	var state := cenario("NB-007", "NB-013")
	Rules.aplicar_status(state, state["jogadores"][1]["ativo"], "envenenado")
	agir(state, {"tipo": "encerrar_turno"})
	igual(state["jogadores"][1]["ativo"]["dano"], 10, "veneno causa 10 no checkup")


func test_queimadura_checkup_e_cura() -> void:
	var state := cenario("NB-007", "NB-013")
	Rules.aplicar_status(state, state["jogadores"][1]["ativo"], "queimado")
	state["forcar_moedas"] = [true]  # cara cura
	agir(state, {"tipo": "encerrar_turno"})
	var alvo: Dictionary = state["jogadores"][1]["ativo"]
	igual(alvo["dano"], 20, "queimadura causa 20")
	ok(not Rules.tem_status(alvo, "queimado"), "cara curou a queimadura")


func test_adormecido_bloqueia_e_acorda() -> void:
	var state := cenario("NB-007", "NB-013")
	reservar(state, 0, "NB-010")
	energizar(state["jogadores"][0]["ativo"], ["brasa"])
	Rules.aplicar_status(state, state["jogadores"][0]["ativo"], "adormecido")
	ok(not tem_acao(state, {"tipo": "atacar"}), "adormecido não ataca")
	ok(not tem_acao(state, {"tipo": "recuar"}), "adormecido não recua")
	state["forcar_moedas"] = [true]  # acorda no checkup
	agir(state, {"tipo": "encerrar_turno"})
	ok(not Rules.tem_status(state["jogadores"][0]["ativo"], "adormecido"), "cara acorda")


func test_paralisia_cura_no_fim_do_proprio_turno() -> void:
	var state := cenario("NB-007", "NB-013")
	energizar(state["jogadores"][0]["ativo"], ["brasa"])
	# Paralisado no turno do oponente (turno 4); agora é o turno 5 do dono.
	var ativo: Dictionary = state["jogadores"][0]["ativo"]
	Rules.aplicar_status(state, ativo, "paralisado")
	ativo["status"][0]["turno"] = state["turno"] - 1
	ok(not tem_acao(state, {"tipo": "atacar"}), "paralisado não ataca no próprio turno")
	agir(state, {"tipo": "encerrar_turno"})
	ok(not Rules.tem_status(ativo, "paralisado"), "paralisia cura ao fim do turno do dono")


func test_status_exclusivos_se_substituem() -> void:
	var state := cenario("NB-007", "NB-013")
	var alvo: Dictionary = state["jogadores"][1]["ativo"]
	Rules.aplicar_status(state, alvo, "envenenado")
	Rules.aplicar_status(state, alvo, "adormecido")
	Rules.aplicar_status(state, alvo, "paralisado")
	ok(Rules.tem_status(alvo, "envenenado"), "veneno coexiste")
	ok(not Rules.tem_status(alvo, "adormecido"), "paralisia substitui sono")
	ok(Rules.tem_status(alvo, "paralisado"), "paralisado ativo")

# ------------------------------------------------ aliados (regras de categoria)

func test_mentor_um_por_turno() -> void:
	var state := cenario("NB-007", "NB-013")
	state["jogadores"][0]["mao"] = ["AL-002", "AL-002"]  # 2× Recruta Bruno
	agir(state, {"tipo": "jogar_aliado"})
	ok(not tem_acao(state, {"tipo": "jogar_aliado"}), "1 mentor por turno")


func test_item_sem_limite() -> void:
	var state := cenario("NB-007", "NB-013")
	state["jogadores"][0]["ativo"]["dano"] = 40
	state["jogadores"][0]["mao"] = ["AL-009", "AL-009"]  # 2× Poção do Vale
	agir(state, {"tipo": "jogar_aliado"})
	ok(tem_acao(state, {"tipo": "jogar_aliado"}), "itens sem limite por turno")


func test_ferramenta_uma_por_monstro() -> void:
	var state := cenario("NB-007", "NB-013")
	state["jogadores"][0]["mao"] = ["AL-015", "AL-016"]
	agir(state, {"tipo": "anexar_ferramenta"})
	ok(not tem_acao(state, {"tipo": "anexar_ferramenta"}), "1 ferramenta por monstro")

# ------------------------------------------------ validação de deck

func test_validar_deck() -> void:
	var decks := CardDB.load_decks()
	igual(Rules.validar_deck(db, decks[0]["cartas"]).size(), 0, "deck Fúria Vulcânica válido")
	igual(Rules.validar_deck(db, decks[1]["cartas"]).size(), 0, "deck Maré Constante válido")

	var tres_copias: Array = decks[0]["cartas"].duplicate()
	tres_copias[19] = "NB-007"  # 3ª cópia de Fagulho
	ok(Rules.validar_deck(db, tres_copias).size() > 0, "3 cópias é inválido")

	ok(Rules.validar_deck(db, ["NB-007"]).size() > 0, "tamanho errado é inválido")
