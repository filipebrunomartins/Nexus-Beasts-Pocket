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

	# 3) Anexar mana no Ativo (nível 1 erra o alvo 20% das vezes)
	if por_tipo.has("anexar_mana"):
		var lista: Array = por_tipo["anexar_mana"]
		if nivel <= 1 and rng.randf() < 0.2:
			return lista[rng.randi_range(0, lista.size() - 1)]
		for acao in lista:
			if acao["alvo"]["pos"] == "ativo":
				return acao
		return lista[0]

	# 4) Habilidades de benefício puro (acelerar mana, curar quando ferido)
	if por_tipo.has("usar_habilidade"):
		return por_tipo["usar_habilidade"][0]

	# 5) Atacar com o maior dano estimado
	if por_tipo.has("atacar"):
		var melhor: Dictionary = por_tipo["atacar"][0]
		var melhor_dano := -1
		for acao in por_tipo["atacar"]:
			var dano := _dano_estimado(db, state, lado, acao)
			if dano > melhor_dano:
				melhor_dano = dano
				melhor = acao
		return melhor

	return {"tipo": "encerrar_turno"}


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
