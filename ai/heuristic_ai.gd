class_name HeuristicAI
extends RefCounted
## IA dos desafiantes (README 7.5.5). Os níveis escalam por mapa:
##  1 — Vale do Despertar: heurística básica com 20% de "erros" propositais.
##  2 — Costa: sem erros; usa Mentores/Itens e recua monstros quase nocauteados.
##  3 — Picos: prioriza alvos Ω, aplica status na hora certa, carrega 2º atacante.
##  4 — Abismo: pondera 1 jogada à frente (minimax raso).
## Os níveis 2–4 são refinados nas Etapas 9–10; o nível 1 é o piso funcional.

var nivel := 1
var rng := RandomNumberGenerator.new()


func _init(nivel_: int = 1, seed_: int = 0) -> void:
	nivel = nivel_
	rng.seed = seed_ if seed_ != 0 else randi()


## Escolhe uma ação entre as legais. Nunca devolve vazio se houver ação.
func escolher(db: CardDB, state: Dictionary, lado: int) -> Dictionary:
	var acoes := Rules.acoes_legais(db, state)
	if acoes.is_empty():
		return {}
	match state["fase"]:
		"setup":
			return _escolher_setup(db, state, lado, acoes)
		"promocao":
			return _escolher_promocao(db, state, lado, acoes)
	return _escolher_jogada(db, state, lado, acoes)


func _escolher_setup(db: CardDB, state: Dictionary, _lado: int, acoes: Array) -> Dictionary:
	# Posiciona como Ativo o básico de maior PS.
	var melhor: Dictionary = acoes[0]
	var melhor_ps := -1
	for acao in acoes:
		var p: Dictionary = state["jogadores"][acao["lado"]]
		var ps := int(db.get_card(p["mao"][acao["indice_mao"]]).get("ps", 0))
		if ps > melhor_ps:
			melhor_ps = ps
			melhor = acao
	return melhor


func _escolher_promocao(db: CardDB, state: Dictionary, lado: int, acoes: Array) -> Dictionary:
	if nivel <= 1:
		return acoes[rng.randi_range(0, acoes.size() - 1)]
	# Níveis 2+: promove quem tem mais energia anexada (mantém pressão).
	var melhor: Dictionary = acoes[0]
	var melhor_valor := -1
	for acao in acoes:
		var besta: Dictionary = state["jogadores"][lado]["reserva"][acao["idx"]]
		var valor := (besta["energias"] as Array).size() * 100 + Rules.ps_total(db, besta) - int(besta["dano"])
		if valor > melhor_valor:
			melhor_valor = valor
			melhor = acao
	return melhor


func _escolher_jogada(db: CardDB, state: Dictionary, lado: int, acoes: Array) -> Dictionary:
	var por_tipo := {}
	for acao in acoes:
		if not por_tipo.has(acao["tipo"]):
			por_tipo[acao["tipo"]] = []
		por_tipo[acao["tipo"]].append(acao)

	# 1) Encher a Reserva (básicos e relíquias)
	if por_tipo.has("colocar_reserva"):
		return por_tipo["colocar_reserva"][0]

	# 2) Evoluir sempre que possível (prefere a Linha de Frente)
	if por_tipo.has("evoluir"):
		for acao in por_tipo["evoluir"]:
			if acao["alvo"]["pos"] == "ativo":
				return acao
		return por_tipo["evoluir"][0]

	# 3) Anexar mana (nível 1 erra o alvo 20% das vezes; nível 3+ carrega
	#    um segundo atacante na Reserva quando o Ativo já está pronto)
	if por_tipo.has("anexar_mana"):
		var lista: Array = por_tipo["anexar_mana"]
		if nivel <= 1 and rng.randf() < 0.2:
			return lista[rng.randi_range(0, lista.size() - 1)]
		if nivel >= 3 and _ativo_esta_carregado(db, state, lado):
			var melhor := _acao_mana_na_reserva(db, state, lado, lista)
			if not melhor.is_empty():
				return melhor
		for acao in lista:
			if acao["alvo"]["pos"] == "ativo":
				return acao
		return lista[0]

	# 4) Habilidades de benefício puro (acelerar mana, curar quando ferido)
	if por_tipo.has("usar_habilidade"):
		return por_tipo["usar_habilidade"][0]

	# 4.5) Nível 2+: usa Mentores/Itens/Ferramentas e recua quase-nocauteados
	if nivel >= 2:
		var apoio := _jogada_de_apoio(db, state, lado, por_tipo)
		if not apoio.is_empty():
			return apoio

	# 5) Atacar: nível 4 simula cada opção; níveis 1–3 pontuam heurísticas
	if por_tipo.has("atacar"):
		if nivel >= 4:
			return _melhor_por_simulacao(db, state, por_tipo["atacar"], lado)
		var melhor: Dictionary = por_tipo["atacar"][0]
		var melhor_pontos := -99999
		for acao in por_tipo["atacar"]:
			var pontos := _pontuar_ataque(db, state, lado, acao)
			if pontos > melhor_pontos:
				melhor_pontos = pontos
				melhor = acao
		return melhor

	return {"tipo": "encerrar_turno"}


func _ativo_esta_carregado(db: CardDB, state: Dictionary, lado: int) -> bool:
	var ativo: Variant = state["jogadores"][lado]["ativo"]
	if ativo == null:
		return false
	var card := Rules.carta_de(db, ativo)
	if card["categoria"] != "besta":
		return true
	for atk in card["ataques"]:
		if not Rules.pode_pagar(db, state, lado, ativo, atk):
			return false
	return true


func _acao_mana_na_reserva(db: CardDB, state: Dictionary, lado: int, lista: Array) -> Dictionary:
	# Prefere a besta da Reserva com maior PS (o próximo tanque/atacante).
	var melhor: Dictionary = {}
	var melhor_ps := -1
	for acao in lista:
		if acao["alvo"]["pos"] != "reserva":
			continue
		var besta: Dictionary = state["jogadores"][lado]["reserva"][acao["alvo"]["idx"]]
		var ps := Rules.ps_total(db, besta)
		if ps > melhor_ps:
			melhor_ps = ps
			melhor = acao
	return melhor


## Pontuação heurística de um ataque (níveis 1–3).
func _pontuar_ataque(db: CardDB, state: Dictionary, lado: int, acao: Dictionary) -> int:
	var pontos := _dano_estimado(db, state, lado, acao)
	if nivel < 3:
		return pontos
	var op: Dictionary = state["jogadores"][1 - lado]
	var atacante: Dictionary = state["jogadores"][lado]["ativo"]
	var ataque: Dictionary = Rules.carta_de(db, atacante)["ataques"][acao["indice_ataque"]]

	# Alvo do ataque (escolhido ou o Ativo inimigo)
	var alvo: Variant = op["ativo"]
	var params: Dictionary = acao.get("params", {})
	if params.has("alvo_oponente"):
		alvo = Rules.besta_em(state, 1 - lado, params["alvo_oponente"])
	if alvo != null:
		var restante: int = Rules.ps_total(db, alvo) - int(alvo["dano"])
		if pontos >= restante:
			# Nocaute! Caça Ω: vale 2 selos.
			var selos := 2 if Rules.carta_de(db, alvo).get("omega", false) else 1
			pontos += 100 * selos
	# Status na hora certa: só se o defensor ainda não tem condição
	for ef in ataque["efeitos"]:
		if ef["bloco"] == "status" and op["ativo"] != null and (op["ativo"]["status"] as Array).is_empty():
			pontos += 15
		if ef["bloco"] == "moeda":
			for sub in ef.get("se_cara", []):
				if sub["bloco"] == "status" and op["ativo"] != null and (op["ativo"]["status"] as Array).is_empty():
					pontos += 8
	return pontos


## Nível 4: aplica cada ação numa cópia do estado e avalia a posição resultante.
func _melhor_por_simulacao(db: CardDB, state: Dictionary, acoes: Array, lado: int) -> Dictionary:
	var melhor: Dictionary = acoes[0]
	var melhor_valor := -INF
	for acao in acoes:
		var copia: Dictionary = state.duplicate(true)
		Rules.aplicar(db, copia, acao)
		var valor := _avaliar(db, copia, lado)
		if valor > melhor_valor:
			melhor_valor = valor
			melhor = acao
	return melhor


## Função de avaliação de posição para o lado dado.
func _avaliar(db: CardDB, state: Dictionary, lado: int) -> float:
	if state["fase"] == "fim":
		if int(state["vencedor"]) == lado:
			return 1000000.0
		if int(state["vencedor"]) == 1 - lado:
			return -1000000.0
		return 0.0
	var valor := 0.0
	valor += int(state["jogadores"][lado]["selos"]) * 2000.0
	valor -= int(state["jogadores"][1 - lado]["selos"]) * 2000.0
	for l in 2:
		var sinal := 1.0 if l != lado else -0.6  # dano no inimigo vale mais
		var p: Dictionary = state["jogadores"][l]
		var bestas: Array = (p["reserva"] as Array).duplicate()
		if p["ativo"] != null:
			bestas.append(p["ativo"])
		for besta in bestas:
			valor += sinal * 300.0 * float(besta["dano"]) / Rules.ps_total(db, besta)
			if l == lado:
				valor += (besta["energias"] as Array).size() * 25.0
	return valor


## Nível 2+: joga cartas de apoio quando fazem sentido e recua o Ativo em risco.
func _jogada_de_apoio(db: CardDB, state: Dictionary, lado: int, por_tipo: Dictionary) -> Dictionary:
	var p: Dictionary = state["jogadores"][lado]

	# Ferramenta no Ativo
	if por_tipo.has("anexar_ferramenta"):
		for acao in por_tipo["anexar_ferramenta"]:
			if acao["alvo"]["pos"] == "ativo":
				return acao

	# Mentores/Itens com condição simples de utilidade
	for acao in por_tipo.get("jogar_aliado", []):
		var card: Dictionary = db.get_card(p["mao"][acao["indice_mao"]])
		match card["id"]:
			"AL-002":  # Recruta Bruno: compre 2
				if (p["mao"] as Array).size() <= 5:
					return acao
			"AL-001":  # Professora Íris: descarta a mão
				if (p["mao"] as Array).size() <= 2:
					return acao
			"AL-003", "AL-009":  # curas: se o alvo está ferido o bastante
				var alvo: Variant = Rules.besta_em(state, lado, acao.get("params", {}).get("alvo_proprio", {"pos": "ativo"}))
				if alvo != null and int(alvo["dano"]) >= 30:
					return acao
			"AL-010":  # Antídoto: se o Ativo tem condição
				if p["ativo"] != null and not (p["ativo"]["status"] as Array).is_empty():
					return acao
			"AL-005", "AL-006", "AL-007", "AL-012":  # benefício direto
				return acao

	# Recuar o Ativo quase nocauteado se houver reserva mais saudável
	if por_tipo.has("recuar") and p["ativo"] != null:
		var ps := Rules.ps_total(db, p["ativo"])
		if int(p["ativo"]["dano"]) * 10 >= ps * 7:  # ≥70% de dano
			var melhor: Dictionary = {}
			var melhor_valor := -1.0
			for acao in por_tipo["recuar"]:
				var besta: Dictionary = p["reserva"][acao["indice_reserva"]]
				var saude := 1.0 - float(besta["dano"]) / Rules.ps_total(db, besta)
				var valor := saude + (besta["energias"] as Array).size() * 0.3
				if saude > 0.5 and valor > melhor_valor:
					melhor_valor = valor
					melhor = acao
			if not melhor.is_empty():
				return melhor
	return {}


## Dano esperado de uma ação de ataque (moedas contam metade).
func _dano_estimado(db: CardDB, state: Dictionary, lado: int, acao: Dictionary) -> int:
	var atacante: Dictionary = state["jogadores"][lado]["ativo"]
	var ataque: Dictionary = Rules.carta_de(db, atacante)["ataques"][acao["indice_ataque"]]
	var dano := int(ataque["dano"])
	for ef in ataque["efeitos"]:
		match ef["bloco"]:
			"moedas_dano":
				@warning_ignore("integer_division")
				dano += int(ef["qtd"]) * int(ef["dano_por_cara"]) / 2
			"dano_alvo_escolha":
				dano += int(ef["valor"])
			"dano_bonus_se":
				if Effects.checar_condicao(db, state, lado, ef["condicao"]):
					dano += int(ef["valor"])
	return dano
