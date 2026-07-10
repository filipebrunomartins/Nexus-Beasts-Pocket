extends NBTest
## Testes do interpretador de efeitos: cada bloco do vocabulário e as
## cartas representativas do set, mais um smoke test de todos os ataques.

# ------------------------------------------------ moedas e status em ataque

func test_moeda_status_queimado() -> void:
	var state := cenario("NB-008", "NB-016")  # Pirandra: Bafo Ardente
	energizar(state["jogadores"][0]["ativo"], ["brasa", "brasa", "brasa"])
	# 1ª moeda: cara queima; 2ª: coroa no checkup mantém a queimadura
	state["forcar_moedas"] = [true, false]
	agir(state, {"tipo": "atacar"})
	ok(Rules.tem_status(state["jogadores"][1]["ativo"], "queimado"), "cara queima")
	# 50 do ataque (60 − 10 da Concha) + 20 da queimadura no checkup
	igual(state["jogadores"][1]["ativo"]["dano"], 70, "dano do ataque + checkup")


func test_moeda_coroa_sem_efeito() -> void:
	var state := cenario("NB-008", "NB-016")
	energizar(state["jogadores"][0]["ativo"], ["brasa", "brasa", "brasa"])
	state["forcar_moedas"] = [false]
	agir(state, {"tipo": "atacar"})
	ok(not Rules.tem_status(state["jogadores"][1]["ativo"], "queimado"), "coroa não queima")


func test_veneno_reforcado_20() -> void:
	var state := cenario("NB-042", "NB-009")  # Reinoturno Ω: Toxina Profunda
	energizar(state["jogadores"][0]["ativo"], ["sombra", "sombra"])
	agir(state, {"tipo": "atacar", "indice_ataque": 0})
	var alvo: Dictionary = state["jogadores"][1]["ativo"]
	# 30 do ataque + 20 do veneno reforçado no checkup que segue o ataque
	igual(alvo["dano"], 50, "dano da Toxina + veneno no checkup")
	agir(state, {"tipo": "encerrar_turno"})
	igual(alvo["dano"], 70, "veneno reforçado tica 20 a cada checkup")


func test_moedas_dano_peixelor() -> void:
	var state := cenario("NB-017", "NB-045")  # Cardume Veloz vs Fortalezaur (sem fraqueza a 💧)
	energizar(state["jogadores"][0]["ativo"], ["mare", "mare"])
	state["forcar_moedas"] = [true, true]
	agir(state, {"tipo": "atacar"})
	igual(state["jogadores"][1]["ativo"]["dano"], 60, "20 + 2 caras de 20")


func test_dano_bonus_se_adormecido() -> void:
	var state := cenario("NB-028", "NB-009")  # Hipnolho: Pesadelo
	energizar(state["jogadores"][0]["ativo"], ["mente", "mente"])
	Rules.aplicar_status(state, state["jogadores"][1]["ativo"], "adormecido")
	agir(state, {"tipo": "atacar", "indice_ataque": 1})
	igual(state["jogadores"][1]["ativo"]["dano"], 60, "30 + 30 com defensor adormecido")


func test_dano_por_energia_extra() -> void:
	var state := cenario("NB-027", "NB-009")  # Astrallume: 🔮🔮⭐, +20/🔮 extra
	energizar(state["jogadores"][0]["ativo"], ["mente", "mente", "mente", "sombra"])
	agir(state, {"tipo": "atacar"})
	igual(state["jogadores"][1]["ativo"]["dano"], 80, "60 + 1 energia 🔮 extra")

# ------------------------------------------------ custos e energia

func test_auto_dano_colapso_verde() -> void:
	var state := cenario("NB-006", "NB-009")  # Selvarok Ω
	energizar(state["jogadores"][0]["ativo"], ["flora", "flora", "flora", "flora"])
	agir(state, {"tipo": "atacar", "indice_ataque": 1})
	igual(state["jogadores"][0]["ativo"]["dano"], 30, "Colapso Verde fere o atacante em 30")


func test_descartar_energia_erupcao() -> void:
	var state := cenario("NB-009", "NB-016")  # Vulkragon: Erupção Total
	energizar(state["jogadores"][0]["ativo"], ["brasa", "brasa", "brasa", "brasa"])
	agir(state, {"tipo": "atacar"})
	igual((state["jogadores"][0]["ativo"]["energias"] as Array).size(), 2, "descarta 2 🔥")


func test_devolver_energia_zumbizz() -> void:
	var state := cenario("NB-022", "NB-009")
	energizar(state["jogadores"][0]["ativo"], ["faisca"])
	energizar(state["jogadores"][1]["ativo"], ["brasa", "brasa"])
	state["forcar_moedas"] = [true]
	agir(state, {"tipo": "atacar"})
	igual((state["jogadores"][1]["ativo"]["energias"] as Array).size(), 1, "cara devolve 1 energia")

# ------------------------------------------------ dano dirigido e em área

func test_dano_alvo_escolha_na_reserva() -> void:
	var state := cenario("NB-024", "NB-009")  # Tempestrix Ω: Circuito Máximo
	var frágil := reservar(state, 1, "NB-013")  # Gotari 60 PS
	energizar(state["jogadores"][0]["ativo"], ["faisca", "faisca", "faisca"])
	agir(state, {"tipo": "atacar", "indice_ataque": 1, "params": {"alvo_oponente": {"pos": "reserva", "idx": 0}}})
	igual(frágil["dano"], 60, "60 direto na reserva (sem fraqueza)")
	igual(state["jogadores"][1]["ativo"]["dano"], 0, "ativo intocado")


func test_terremoto_fere_reserva_propria() -> void:
	var state := cenario("NB-033", "NB-009")  # Titanólito
	var aliado := reservar(state, 0, "NB-031")
	energizar(state["jogadores"][0]["ativo"], ["rocha", "rocha", "rocha", "rocha"])
	agir(state, {"tipo": "atacar"})
	igual(aliado["dano"], 10, "Terremoto causa 10 na própria reserva")

# ------------------------------------------------ bloqueios e reduções

func test_prisao_de_bolhas_bloqueia_recuo() -> void:
	var state := cenario("NB-018", "NB-022")  # vs Zumbizz (recuo 0)
	reservar(state, 1, "NB-013")
	energizar(state["jogadores"][0]["ativo"], ["mare", "mare"])
	agir(state, {"tipo": "atacar", "indice_ataque": 0})
	state["fase"] = "jogando"
	igual(state["jogador_atual"], 1, "vez do defensor")
	ok(not tem_acao(state, {"tipo": "recuar"}), "defensor não pode recuar")


func test_plaquinha_bloqueia_ataque() -> void:
	var state := cenario("NB-055", "NB-022")  # Fofurelho vs Zumbizz
	energizar(state["jogadores"][0]["ativo"], ["faisca"])
	energizar(state["jogadores"][1]["ativo"], ["faisca"])
	state["forcar_moedas"] = [true]
	agir(state, {"tipo": "atacar"})
	ok(not tem_acao(state, {"tipo": "atacar"}), "defensor não pode atacar no próximo turno")


func test_canhao_pesado_bloqueia_proprio_ataque() -> void:
	var state := cenario("NB-045", "NB-009")  # Fortalezaur
	reservar(state, 0, "NB-043")
	reservar(state, 1, "NB-013")
	energizar(state["jogadores"][0]["ativo"], ["aco", "aco", "aco", "aco"])
	agir(state, {"tipo": "atacar"})
	# volta a vez ao jogador 0
	agir(state, {"tipo": "encerrar_turno"})
	ok(not tem_acao(state, {"tipo": "atacar"}), "não ataca no turno seguinte ao Canhão")


func test_muralha_viva_reduz_dano() -> void:
	var state := cenario("NB-036", "NB-011")  # Titanólito Ω vs Lavaboi
	energizar(state["jogadores"][0]["ativo"], ["rocha", "rocha"])
	energizar(state["jogadores"][1]["ativo"], ["brasa", "brasa", "brasa"])
	agir(state, {"tipo": "atacar", "indice_ataque": 0})  # Muralha Viva
	# Lavaboi ataca com 60; Muralha reduz 30
	agir(state, {"tipo": "atacar"})
	igual(state["jogadores"][0]["ativo"]["dano"], 30, "60 − 30 da Muralha Viva")


func test_reducao_passiva_concharrico() -> void:
	var state := cenario("NB-007", "NB-016")  # 20 vs Concha Rígida −10
	energizar(state["jogadores"][0]["ativo"], ["brasa"])
	agir(state, {"tipo": "atacar"})
	igual(state["jogadores"][1]["ativo"]["dano"], 10, "Concha Rígida reduz 10")


func test_escavurso_ignora_reducao() -> void:
	var state := cenario("NB-035", "NB-016")  # Garra Subterrânea ignora redução
	energizar(state["jogadores"][0]["ativo"], ["rocha", "rocha"])
	agir(state, {"tipo": "atacar"})
	igual(state["jogadores"][1]["ativo"]["dano"], 40, "redução ignorada")

# ------------------------------------------------ habilidades passivas

func test_retaliacao_espinhel() -> void:
	var state := cenario("NB-007", "NB-005")  # vs Casca de Espinhos
	energizar(state["jogadores"][0]["ativo"], ["brasa"])
	agir(state, {"tipo": "atacar"})
	igual(state["jogadores"][0]["ativo"]["dano"], 20, "atacante sofre 20 de retaliação")


func test_intangivel_espectrolho() -> void:
	var state := cenario("NB-007", "NB-040")
	energizar(state["jogadores"][0]["ativo"], ["brasa"])
	state["forcar_moedas"] = [true]
	agir(state, {"tipo": "atacar"})
	igual(state["jogadores"][1]["ativo"]["dano"], 0, "Intangível previne o dano com cara")


func test_imune_status_fortalezaur() -> void:
	var state := cenario("NB-010", "NB-045")  # Cinzelim tenta queimar
	energizar(state["jogadores"][0]["ativo"], ["brasa"])
	agir(state, {"tipo": "atacar"})
	ok(not Rules.tem_status(state["jogadores"][1]["ativo"], "queimado"), "Liga Reforçada imune a queimadura")


func test_sobrecarga_reduz_custo() -> void:
	var state := cenario("NB-021", "NB-009")  # Tempestrix: ⚡⚡⚡ com −1⭐ se reserva cheia
	energizar(state["jogadores"][0]["ativo"], ["faisca", "faisca"])
	ok(not tem_acao(state, {"tipo": "atacar"}), "sem reserva cheia, custo integral")
	for c in ["NB-019", "NB-022", "NB-023"]:
		reservar(state, 0, c)
	ok(tem_acao(state, {"tipo": "atacar"}), "com 3 na reserva, custa 1 a menos")


func test_recuo_zero_levitoad() -> void:
	var state := cenario("NB-029", "NB-009")
	reservar(state, 0, "NB-025")
	igual(Rules.custo_recuo(db, state, 0), 1, "sem 🔮, recuo normal")
	energizar(state["jogadores"][0]["ativo"], ["mente"])
	igual(Rules.custo_recuo(db, state, 0), 0, "com 🔮, Levitação zera o recuo")


func test_manto_da_noite_bonus() -> void:
	var state := cenario("NB-039", "NB-009")  # Reinoturno +30 vs envenenado
	energizar(state["jogadores"][0]["ativo"], ["sombra", "sombra", "sombra"])
	Rules.aplicar_status(state, state["jogadores"][1]["ativo"], "envenenado")
	agir(state, {"tipo": "atacar"})
	# 70 + 30 do Manto da Noite + 10 do veneno no checkup
	igual(state["jogadores"][1]["ativo"]["dano"], 110, "bônus do Manto + veneno no checkup")


func test_presenca_mitica_ignora_intangivel() -> void:
	var state := cenario("NB-054", "NB-040")  # Aetherion Ω vs Espectrolho
	energizar(state["jogadores"][0]["ativo"], ["mente", "sombra", "mare"])
	state["forcar_moedas"] = [true]  # seria prevenido sem Presença Mítica
	agir(state, {"tipo": "atacar"})
	ok(state["jogadores"][1]["ativo"] == null or int(state["jogadores"][1]["ativo"]["dano"]) > 0 \
			or state["fase"] != "jogando", "dano atravessa o Intangível")

# ------------------------------------------------ habilidades ativadas

func test_fotossintese_cura() -> void:
	var state := cenario("NB-003", "NB-009")
	state["jogadores"][0]["ativo"]["dano"] = 50
	agir(state, {"tipo": "usar_habilidade"})
	igual(state["jogadores"][0]["ativo"]["dano"], 30, "Fotossíntese cura 20")
	ok(not tem_acao(state, {"tipo": "usar_habilidade"}), "1x por turno")


func test_coracao_de_magma_anexa() -> void:
	var state := cenario("NB-012", "NB-009")
	agir(state, {"tipo": "usar_habilidade"})
	igual(state["jogadores"][0]["ativo"]["energias"], ["brasa"], "anexou 1 🔥 do Núcleo")


func test_elo_cosmico_move_energia() -> void:
	var state := cenario("NB-030", "NB-009")  # Astrallume Ω
	var aliado := reservar(state, 0, "NB-025")
	energizar(aliado, ["mente"])
	# única origem com 🔮 é a reserva; move para o ativo
	agir(state, {"tipo": "usar_habilidade", "alvo": {"pos": "ativo"}})
	ok((state["jogadores"][0]["ativo"]["energias"] as Array).has("mente"), "energia 🔮 movida para o ativo")
	igual((aliado["energias"] as Array).size(), 0, "origem ficou sem a energia")
	ok(not tem_acao(state, {"tipo": "usar_habilidade"}), "Elo Cósmico é 1x por turno")


func test_vento_de_cauda_na_reserva() -> void:
	var state := cenario("NB-011", "NB-009")  # Lavaboi recuo 3
	reservar(state, 0, "NB-058")  # Plumazul na reserva
	igual(Rules.custo_recuo(db, state, 0), 3, "recuo cheio")
	agir(state, {"tipo": "usar_habilidade", "alvo": {"pos": "reserva", "idx": 0}})
	igual(Rules.custo_recuo(db, state, 0), 2, "Vento de Cauda reduz 1")


func test_correnteza_gust_ao_evoluir() -> void:
	var state := cenario("NB-014", "NB-009")  # Ondaluz pronto para evoluir
	reservar(state, 1, "NB-013")
	var p0: Dictionary = state["jogadores"][0]
	p0["ativo"]["entrou_no_turno"] = 0
	p0["mao"] = ["NB-015"]  # Abissarion
	agir(state, {"tipo": "evoluir", "usar_gatilho": true})
	igual(state["jogadores"][1]["ativo"]["carta"], "NB-013", "Correnteza puxou o da reserva")

# ------------------------------------------------ mentores e itens

func test_professora_iris() -> void:
	var state := cenario("NB-007", "NB-013")
	var p0: Dictionary = state["jogadores"][0]
	p0["mao"] = ["AL-001", "NB-010", "NB-011"]
	agir(state, {"tipo": "jogar_aliado"})
	igual((p0["mao"] as Array).size(), 3, "descartou a mão e comprou 3")
	ok((p0["descarte"] as Array).has("NB-010"), "mão antiga no descarte")


func test_recruta_bruno_compra_2() -> void:
	var state := cenario("NB-007", "NB-013")
	var p0: Dictionary = state["jogadores"][0]
	p0["mao"] = ["AL-002"]
	agir(state, {"tipo": "jogar_aliado"})
	igual((p0["mao"] as Array).size(), 2, "comprou 2")


func test_curandeira_maya_cura_50() -> void:
	var state := cenario("NB-009", "NB-013")
	var p0: Dictionary = state["jogadores"][0]
	p0["ativo"]["dano"] = 60
	p0["mao"] = ["AL-003"]
	agir(state, {"tipo": "jogar_aliado"})
	igual(p0["ativo"]["dano"], 10, "curou 50")


func test_capitao_vento_gust() -> void:
	var state := cenario("NB-007", "NB-013")
	reservar(state, 1, "NB-017")
	state["jogadores"][0]["mao"] = ["AL-004"]
	agir(state, {"tipo": "jogar_aliado"})
	igual(state["jogadores"][1]["ativo"]["carta"], "NB-017", "ativo do oponente trocado")


func test_ferreiro_odan_reducao() -> void:
	var state := cenario("NB-043", "NB-011")  # Parafusim (aço) vs Lavaboi
	state["jogadores"][0]["mao"] = ["AL-005"]
	agir(state, {"tipo": "jogar_aliado"})
	energizar(state["jogadores"][1]["ativo"], ["brasa", "brasa", "brasa"])
	agir(state, {"tipo": "encerrar_turno"})
	agir(state, {"tipo": "atacar"})
	# 60 + 20 fraqueza (aço fraco a brasa) − 20 do Ferreiro = 60
	igual(state["jogadores"][0]["ativo"]["dano"], 60, "redução do Ferreiro aplicada")


func test_mare_mestra_suri() -> void:
	var state := cenario("NB-013", "NB-007")
	var alvo := reservar(state, 0, "NB-016")  # Concharrico (maré) na reserva
	state["jogadores"][0]["mao"] = ["AL-006"]
	state["forcar_moedas"] = [true]
	agir(state, {"tipo": "jogar_aliado"})
	igual((alvo["energias"] as Array).size(), 2, "2 energias 💧 anexadas com cara")


func test_rastreadora_kova_busca_basico() -> void:
	var state := cenario("NB-007", "NB-013")
	var p0: Dictionary = state["jogadores"][0]
	p0["deck"] = ["AL-009", "NB-010", "AL-002"]
	p0["mao"] = ["AL-007"]
	agir(state, {"tipo": "jogar_aliado"})
	ok((p0["mao"] as Array).has("NB-010"), "básico veio para a mão")


func test_chamado_do_nexus_condicional() -> void:
	var state := cenario("NB-007", "NB-013")
	var p0: Dictionary = state["jogadores"][0]
	p0["mao"] = ["AL-008"]
	ok(not tem_acao(state, {"tipo": "jogar_aliado"}), "sem estar perdendo por 2, não joga")
	state["jogadores"][1]["selos"] = 2
	ok(tem_acao(state, {"tipo": "jogar_aliado"}), "perdendo por 2 selos, pode jogar")


func test_antidoto_remove_status() -> void:
	var state := cenario("NB-007", "NB-013")
	var p0: Dictionary = state["jogadores"][0]
	Rules.aplicar_status(state, p0["ativo"], "envenenado")
	Rules.aplicar_status(state, p0["ativo"], "adormecido")
	p0["mao"] = ["AL-010"]
	agir(state, {"tipo": "jogar_aliado"})
	igual((p0["ativo"]["status"] as Array).size(), 0, "todas as condições removidas")


func test_botas_de_salto() -> void:
	var state := cenario("NB-011", "NB-013")  # recuo 3
	reservar(state, 0, "NB-007")
	state["jogadores"][0]["mao"] = ["AL-011"]
	agir(state, {"tipo": "jogar_aliado"})
	igual(Rules.custo_recuo(db, state, 0), 2, "Botas reduzem 1 neste turno")


func test_sino_do_recuo_troca_gratis() -> void:
	var state := cenario("NB-011", "NB-013")
	reservar(state, 0, "NB-007")
	state["jogadores"][0]["mao"] = ["AL-013"]
	agir(state, {"tipo": "jogar_aliado"})
	igual(state["jogadores"][0]["ativo"]["carta"], "NB-007", "trocou sem pagar recuo")


func test_lente_de_batalha_revela() -> void:
	var state := cenario("NB-007", "NB-013")
	state["jogadores"][0]["mao"] = ["AL-014"]
	agir(state, {"tipo": "jogar_aliado"})
	igual((state["revelado"]["cartas"] as Array).size(), 3, "3 cartas reveladas")

# ------------------------------------------------ ferramentas e relíquias

func test_amuleto_vital_ps() -> void:
	var state := cenario("NB-007", "NB-013")
	var p0: Dictionary = state["jogadores"][0]
	p0["mao"] = ["AL-015"]
	agir(state, {"tipo": "anexar_ferramenta"})
	igual(Rules.ps_total(db, p0["ativo"]), 80, "60 + 20 do Amuleto")


func test_garra_afiada_dano() -> void:
	var state := cenario("NB-007", "NB-009")
	var p0: Dictionary = state["jogadores"][0]
	p0["mao"] = ["AL-016"]
	agir(state, {"tipo": "anexar_ferramenta"})
	energizar(p0["ativo"], ["brasa"])
	agir(state, {"tipo": "atacar"})
	igual(state["jogadores"][1]["ativo"]["dano"], 30, "20 + 10 da Garra Afiada")


func test_manto_espinhoso_retaliacao() -> void:
	var state := cenario("NB-007", "NB-013")
	var p1: Dictionary = state["jogadores"][1]
	p1["ativo"]["ferramenta"] = "AL-017"
	energizar(state["jogadores"][0]["ativo"], ["brasa"])
	agir(state, {"tipo": "atacar"})
	igual(state["jogadores"][0]["ativo"]["dano"], 10, "Manto Espinhoso devolve 10")


func test_reliquia_sem_selo() -> void:
	var state := cenario("NB-011", "NB-013")
	var p1: Dictionary = state["jogadores"][1]
	p1["ativo"] = Rules.nova_besta(db, "AL-018", 0)  # Relíquia de Âmbar (40 PS)
	reservar(state, 1, "NB-013")
	energizar(state["jogadores"][0]["ativo"], ["brasa", "brasa", "brasa"])
	agir(state, {"tipo": "atacar"})
	igual(state["jogadores"][0]["selos"], 0, "nocaute de relíquia não dá selo")


func test_reliquia_entra_pela_mao() -> void:
	var state := cenario("NB-007", "NB-013")
	state["jogadores"][0]["mao"] = ["AL-018"]
	agir(state, {"tipo": "colocar_reserva"})
	igual((state["jogadores"][0]["reserva"] as Array).size(), 1, "relíquia entra como besta")

# ------------------------------------------------ smoke test: todo o set

func test_smoke_todos_os_ataques() -> void:
	for card in db.all_cards():
		if card["categoria"] != "besta":
			continue
		for ai in (card["ataques"] as Array).size():
			var state := cenario(card["id"], "NB-009")  # alvo 160 PS
			reservar(state, 0, "NB-055")
			reservar(state, 1, "NB-013")
			var atacante: Dictionary = state["jogadores"][0]["ativo"]
			var custo: Array = card["ataques"][ai]["custo"]
			var energias: Array = []
			for c in custo:
				energias.append(_energia_para(card, c))
			energizar(atacante, energias)
			var acao := achar_acao(state, {"tipo": "atacar", "indice_ataque": ai})
			if acao.is_empty():
				falhas.append("%s: ataque %d sem ação legal" % [card["id"], ai])
				continue
			var antes := (state["log"] as Array).size()
			if not Rules.aplicar(db, state, acao):
				falhas.append("%s: ataque %d falhou ao aplicar" % [card["id"], ai])
			ok((state["log"] as Array).size() > antes, "%s: ataque %d gerou log" % [card["id"], ai])


func _energia_para(card: Dictionary, custo: String) -> String:
	if custo != "qualquer":
		return custo
	var tipo: String = card.get("tipo", "flora")
	if db.get_type(tipo).get("tem_energia", false):
		return tipo
	return "flora"
