class_name Rules
extends RefCounted
## Motor de regras do Nexus Beasts Pocket — biblioteca pura (Parte 1 do design).
## O estado da partida é um Dictionary serializável; toda mutação passa por
## Rules.aplicar(db, state, acao). Sem Nodes, sem UI, sem rede.
##
## Convenções:
##  - "lado" = 0 ou 1 (índice em state.jogadores)
##  - posição de besta: {"pos": "ativo"} ou {"pos": "reserva", "idx": N}
##  - moedas: true = cara

const SELOS_VITORIA := 3
const TAMANHO_DECK := 20
const MAO_INICIAL := 5
const LIMITE_MAO := 10
const LIMITE_RESERVA := 3
const TURNO_EMPATE := 30
const FRAQUEZA_BONUS := 20

# ============================================================ criação

## primeiro: -1 = cara ou coroa decide; 0/1 força quem começa (testes/tutorial).
static func nova_partida(db: CardDB, deck0: Array, deck1: Array, tipos0: Array, tipos1: Array, seed_: int, primeiro: int = -1) -> Dictionary:
	var state := {
		"turno": 0,
		"jogador_atual": -1,
		"primeiro_jogador": 0,
		"fase": "setup",            # setup -> jogando -> promocao -> fim
		"vencedor": -1,              # 0/1, 2 = empate
		"promocoes_pendentes": [],   # lados aguardando promover
		"rng_seed": seed_,
		"rng_state": 0,
		"forcar_moedas": [],         # fila de moedas forçadas (testes)
		"log": [],
		"jogadores": [],
	}
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_
	state["primeiro_jogador"] = primeiro if primeiro >= 0 else (0 if rng.randf() < 0.5 else 1)
	for cfg in [[deck0, tipos0], [deck1, tipos1]]:
		var p := _novo_jogador(cfg[0], cfg[1])
		_embaralhar(p["deck"], rng)
		_comprar_mao_inicial(db, p, rng)
		p["proxima_mana"] = _sortear_mana(p, rng)
		state["jogadores"].append(p)
	state["rng_state"] = rng.state
	_log(state, "Partida criada. Começa o jogador %d." % state["primeiro_jogador"])
	return state


static func _novo_jogador(deck: Array, tipos_mana: Array) -> Dictionary:
	return {
		"deck": deck.duplicate(),
		"mao": [],
		"descarte": [],
		"ativo": null,
		"reserva": [],
		"selos": 0,
		"tipos_mana": tipos_mana.duplicate(),
		"proxima_mana": "",
		"mana_atual": "",              # "" = sem mana disponível neste turno
		"mana_anexada": false,
		"mentor_jogado": false,
		"recuou": false,
		"buffs": {},                   # ex.: {"reducao_recuo": 1}
	}


static func nova_besta(db: CardDB, card_id: String, turno: int) -> Dictionary:
	var card := db.get_card(card_id)
	var besta := {
		"carta": card_id,
		"dano": 0,
		"energias": [],
		"ferramenta": null,
		"status": [],                  # [{"id": "envenenado", "dano": 10, "turno": N}]
		"pilha": [card_id],            # carta atual + pré-evoluções (p/ descarte)
		"entrou_no_turno": turno,
		"evoluiu_no_turno": -1,
		"usou_habilidade_no_turno": -1,
		"intangivel_no_turno": -1,
		"nao_ataca_ate": -1,           # bloqueado enquanto turno <= valor
		"nao_recua_ate": -1,
		"buffs": [],                   # [{"tipo": "reducao_dano", "valor": 30, "ate_turno": N}]
	}
	if card["categoria"] == "reliquia":
		besta["reliquia"] = true
	return besta


static func _comprar_mao_inicial(db: CardDB, p: Dictionary, rng: RandomNumberGenerator) -> void:
	# O jogo garante ao menos 1 besta Básica na mão inicial (regra 1.3).
	for tentativa in 100:
		p["deck"].append_array(p["mao"])
		p["mao"] = []
		_embaralhar(p["deck"], rng)
		for i in MAO_INICIAL:
			p["mao"].append(p["deck"].pop_front())
		for id in p["mao"]:
			if CardDB.is_basic_beast(db.get_card(id)):
				return
	push_error("Deck sem besta Básica suficiente para mão inicial")


static func validar_deck(db: CardDB, deck: Array) -> PackedStringArray:
	var erros: PackedStringArray = []
	if deck.size() != TAMANHO_DECK:
		erros.append("O baralho deve ter %d cartas (tem %d)." % [TAMANHO_DECK, deck.size()])
	var por_nome: Dictionary = {}
	var tem_basico := false
	for id in deck:
		if not db.has_card(id):
			erros.append("Carta inexistente: %s" % id)
			continue
		var card := db.get_card(id)
		por_nome[card["nome"]] = int(por_nome.get(card["nome"], 0)) + 1
		if CardDB.is_basic_beast(card):
			tem_basico = true
	for nome in por_nome:
		if por_nome[nome] > 2:
			erros.append("Máximo 2 cópias de \"%s\" (tem %d)." % [nome, por_nome[nome]])
	if not tem_basico:
		erros.append("O baralho precisa de ao menos 1 besta Básica.")
	return erros


static func sugerir_tipos_mana(db: CardDB, deck: Array) -> Array:
	var tipos := {}
	for id in deck:
		var card := db.get_card(id)
		if card["categoria"] != "besta":
			continue
		for atk in card["ataques"]:
			for custo in atk["custo"]:
				if custo != "qualquer":
					tipos[custo] = true
	var lista := tipos.keys()
	lista.sort()
	return lista if not lista.is_empty() else ["flora"]

# ============================================================ RNG / moedas

static func _rng_de(state: Dictionary) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = state["rng_seed"]
	if int(state["rng_state"]) != 0:
		rng.state = state["rng_state"]
	return rng


static func moeda(state: Dictionary, motivo: String = "") -> bool:
	var cara: bool
	if not (state["forcar_moedas"] as Array).is_empty():
		cara = state["forcar_moedas"].pop_front()
	else:
		var rng := _rng_de(state)
		cara = rng.randf() < 0.5
		state["rng_state"] = rng.state
	_log(state, "Moeda%s: %s" % [(" (%s)" % motivo) if motivo else "", "CARA" if cara else "COROA"])
	return cara


static func _rand_int(state: Dictionary, max_exclusive: int) -> int:
	var rng := _rng_de(state)
	var v := rng.randi_range(0, max_exclusive - 1)
	state["rng_state"] = rng.state
	return v


static func _embaralhar(arr: Array, rng: RandomNumberGenerator) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp


static func _sortear_mana(p: Dictionary, rng: RandomNumberGenerator) -> String:
	var tipos: Array = p["tipos_mana"]
	return tipos[rng.randi_range(0, tipos.size() - 1)]

# ============================================================ consultas

static func jogador(state: Dictionary, lado: int) -> Dictionary:
	return state["jogadores"][lado]


static func besta_em(state: Dictionary, lado: int, pos: Dictionary) -> Variant:
	var p := jogador(state, lado)
	if pos["pos"] == "ativo":
		return p["ativo"]
	var idx := int(pos.get("idx", -1))
	if idx >= 0 and idx < (p["reserva"] as Array).size():
		return p["reserva"][idx]
	return null


static func carta_de(db: CardDB, besta: Dictionary) -> Dictionary:
	return db.get_card(besta["carta"])


## PS máximo considerando Ferramenta (Amuleto Vital) e relíquias.
static func ps_total(db: CardDB, besta: Dictionary) -> int:
	var card := carta_de(db, besta)
	var ps: int
	if card["categoria"] == "reliquia":
		ps = int(card["reliquia"]["ps"])
	else:
		ps = int(card["ps"])
	if besta["ferramenta"] != null:
		for ef in db.get_card(besta["ferramenta"]).get("efeitos", []):
			if ef["bloco"] == "ps_bonus":
				ps += int(ef["valor"])
	return ps


static func tem_status(besta: Dictionary, id: String) -> bool:
	for s in besta["status"]:
		if s["id"] == id:
			return true
	return false


static func _remover_status(besta: Dictionary, id: String) -> void:
	besta["status"] = besta["status"].filter(func(s): return s["id"] != id)


static func aplicar_status(state: Dictionary, besta: Dictionary, id: String, dano_checkup: int = 0) -> void:
	# Adormecido/Paralisado/Confuso substituem-se; Envenenado/Queimado coexistem (1.6).
	if id in ["adormecido", "paralisado", "confuso"]:
		for excl in ["adormecido", "paralisado", "confuso"]:
			_remover_status(besta, excl)
	else:
		_remover_status(besta, id)
	var entry := {"id": id, "turno": state["turno"]}
	if id == "envenenado":
		entry["dano"] = dano_checkup if dano_checkup > 0 else 10
	besta["status"].append(entry)


static func curar_status(besta: Dictionary) -> void:
	besta["status"] = []


static func habilidade_passiva(db: CardDB, besta: Dictionary, bloco: String) -> Variant:
	## Devolve o efeito passivo com esse bloco, ou null. Relíquias não têm habilidade.
	var card := carta_de(db, besta)
	var hab: Variant = card.get("habilidade")
	if hab == null or hab["modo"] != "passiva":
		return null
	for ef in hab["efeitos"]:
		if ef["bloco"] == bloco:
			return ef
	return null


static func custo_recuo(db: CardDB, state: Dictionary, lado: int) -> int:
	var p := jogador(state, lado)
	var besta: Dictionary = p["ativo"]
	var card := carta_de(db, besta)
	var custo: int = int(card["reliquia"]["recuo"]) if card["categoria"] == "reliquia" else int(card["recuo"])
	var zero: Variant = habilidade_passiva(db, besta, "recuo_zero_se")
	if zero != null:
		match zero["condicao"]:
			"sempre":
				custo = 0
			"tem_energia_tipo":
				if besta["energias"].has(zero["tipo"]):
					custo = 0
	custo -= int(p["buffs"].get("reducao_recuo", 0))
	return maxi(custo, 0)


## Verifica se as energias anexadas pagam o custo do ataque (custos tipados
## consomem energia do tipo; "qualquer" aceita o restante).
static func pode_pagar(db: CardDB, state: Dictionary, lado: int, besta: Dictionary, ataque: Dictionary) -> bool:
	var custo: Array = ataque["custo"].duplicate()
	# Sobrecarga (Tempestrix): -1 ⭐ com Reserva cheia.
	var red: Variant = habilidade_passiva(db, besta, "custo_reduzido_se")
	if red != null and red["condicao"] == "reserva_cheia" \
			and (jogador(state, lado)["reserva"] as Array).size() >= LIMITE_RESERVA:
		for i in int(red["qtd"]):
			var qi := custo.find("qualquer")
			if qi >= 0:
				custo.remove_at(qi)
			elif not custo.is_empty():
				custo.pop_back()
	var pool: Array = besta["energias"].duplicate()
	var qualquer := 0
	for c in custo:
		if c == "qualquer":
			qualquer += 1
			continue
		var i := pool.find(c)
		if i < 0:
			return false
		pool.remove_at(i)
	return pool.size() >= qualquer


static func bestas_em_jogo(p: Dictionary) -> int:
	return (0 if p["ativo"] == null else 1) + (p["reserva"] as Array).size()

# ============================================================ ações legais

static func acoes_legais(db: CardDB, state: Dictionary) -> Array:
	var acoes: Array = []
	match state["fase"]:
		"setup":
			return _acoes_setup(db, state)
		"promocao":
			var lado: int = state["promocoes_pendentes"][0]
			var p := jogador(state, lado)
			for i in (p["reserva"] as Array).size():
				acoes.append({"tipo": "promover", "lado": lado, "idx": i})
			return acoes
		"fim":
			return []
	var lado: int = state["jogador_atual"]
	var p := jogador(state, lado)
	var turno: int = state["turno"]

	# Colocar básicos na Reserva / jogar relíquias
	if (p["reserva"] as Array).size() < LIMITE_RESERVA:
		for i in (p["mao"] as Array).size():
			var card := db.get_card(p["mao"][i])
			if CardDB.is_basic_beast(card) or card["categoria"] == "reliquia":
				acoes.append({"tipo": "colocar_reserva", "indice_mao": i})

	# Evoluir
	for i in (p["mao"] as Array).size():
		var card := db.get_card(p["mao"][i])
		if card["categoria"] == "besta" and int(card["estagio"]) > 0:
			for pos in _todas_posicoes(p):
				var besta: Dictionary = besta_em(state, lado, pos)
				if _pode_evoluir(state, besta, card, turno):
					acoes.append({"tipo": "evoluir", "indice_mao": i, "alvo": pos})
					# Variante usando o gatilho de evolução (ex.: Correnteza)
					var hab: Variant = card.get("habilidade")
					if hab != null and hab["modo"] == "gatilho_evoluir" \
							and not (jogador(state, 1 - lado)["reserva"] as Array).is_empty():
						acoes.append({"tipo": "evoluir", "indice_mao": i, "alvo": pos, "usar_gatilho": true})

	# Anexar mana (1/turno)
	if p["mana_atual"] != "" and not p["mana_anexada"]:
		for pos in _todas_posicoes(p):
			acoes.append({"tipo": "anexar_mana", "alvo": pos})

	# Jogar aliados
	for i in (p["mao"] as Array).size():
		var card := db.get_card(p["mao"][i])
		match card["categoria"]:
			"mentor":
				if not p["mentor_jogado"] and _condicao_uso_ok(state, lado, card):
					acoes.append_array(Effects.acoes_de_aliado(db, state, lado, i, card))
			"item":
				if _condicao_uso_ok(state, lado, card):
					acoes.append_array(Effects.acoes_de_aliado(db, state, lado, i, card))
			"ferramenta":
				for pos in _todas_posicoes(p):
					var besta: Dictionary = besta_em(state, lado, pos)
					if besta["ferramenta"] == null and not besta.get("reliquia", false):
						acoes.append({"tipo": "anexar_ferramenta", "indice_mao": i, "alvo": pos})

	# Habilidades ativadas
	for pos in _todas_posicoes(p):
		var besta: Dictionary = besta_em(state, lado, pos)
		acoes.append_array(Effects.acoes_de_habilidade(db, state, lado, pos, besta))

	# Descartar relíquia da Linha de Frente (a qualquer momento no seu turno)
	if p["ativo"] != null and p["ativo"].get("reliquia", false) and not (p["reserva"] as Array).is_empty():
		acoes.append({"tipo": "descartar_reliquia"})

	# Recuar (1/turno)
	if p["ativo"] != null and not p["recuou"] and not (p["reserva"] as Array).is_empty() \
			and not tem_status(p["ativo"], "adormecido") and not tem_status(p["ativo"], "paralisado") \
			and turno > int(p["ativo"]["nao_recua_ate"]) \
			and (p["ativo"]["energias"] as Array).size() >= custo_recuo(db, state, lado):
		for i in (p["reserva"] as Array).size():
			acoes.append({"tipo": "recuar", "indice_reserva": i})

	# Atacar (encerra o turno)
	if p["ativo"] != null and not tem_status(p["ativo"], "adormecido") \
			and not tem_status(p["ativo"], "paralisado") \
			and turno > int(p["ativo"]["nao_ataca_ate"]):
		var card := carta_de(db, p["ativo"])
		if card["categoria"] == "besta":
			for ai in (card["ataques"] as Array).size():
				if pode_pagar(db, state, lado, p["ativo"], card["ataques"][ai]):
					acoes.append_array(Effects.acoes_de_ataque(db, state, lado, ai, card["ataques"][ai]))

	acoes.append({"tipo": "encerrar_turno"})
	return acoes


static func _acoes_setup(db: CardDB, state: Dictionary) -> Array:
	# Cada jogador posiciona 1 básico como Ativo (o motor coloca demais básicos via ações normais depois).
	var acoes: Array = []
	for lado in 2:
		var p := jogador(state, lado)
		if p["ativo"] != null:
			continue
		for i in (p["mao"] as Array).size():
			if CardDB.is_basic_beast(db.get_card(p["mao"][i])):
				acoes.append({"tipo": "posicionar_ativo", "lado": lado, "indice_mao": i})
		return acoes  # um lado por vez (0 primeiro)
	return acoes


static func _todas_posicoes(p: Dictionary) -> Array:
	var lista: Array = []
	if p["ativo"] != null:
		lista.append({"pos": "ativo"})
	for i in (p["reserva"] as Array).size():
		lista.append({"pos": "reserva", "idx": i})
	return lista


static func _pode_evoluir(state: Dictionary, besta: Dictionary, carta_evolucao: Dictionary, turno: int) -> bool:
	if besta.get("reliquia", false):
		return false
	if carta_evolucao["evolui_de"] != besta["carta"]:
		return false
	if turno <= 2:  # nenhum jogador evolui no seu 1º turno
		return false
	if int(besta["entrou_no_turno"]) >= turno:
		return false
	if int(besta["evoluiu_no_turno"]) == turno:
		return false
	return true


static func _condicao_uso_ok(state: Dictionary, lado: int, card: Dictionary) -> bool:
	var cond: Variant = card.get("condicao_uso")
	if cond == null:
		return true
	if cond["bloco"] == "condicao_selos":
		var meus: int = jogador(state, lado)["selos"]
		var deles: int = jogador(state, 1 - lado)["selos"]
		return deles - meus >= int(cond["diferenca_minima"])
	return true

# ============================================================ aplicar ações

static func aplicar(db: CardDB, state: Dictionary, acao: Dictionary) -> bool:
	if state["fase"] == "fim":
		push_error("Partida encerrada")
		return false
	match acao["tipo"]:
		"posicionar_ativo":
			return _ac_posicionar_ativo(db, state, acao)
		"promover":
			return _ac_promover(db, state, acao)
		"colocar_reserva":
			return _ac_colocar_reserva(db, state, acao)
		"evoluir":
			return _ac_evoluir(db, state, acao)
		"anexar_mana":
			return _ac_anexar_mana(db, state, acao)
		"anexar_ferramenta":
			return _ac_anexar_ferramenta(db, state, acao)
		"jogar_aliado":
			return _ac_jogar_aliado(db, state, acao)
		"usar_habilidade":
			return _ac_usar_habilidade(db, state, acao)
		"descartar_reliquia":
			return _ac_descartar_reliquia(db, state, acao)
		"recuar":
			return _ac_recuar(db, state, acao)
		"atacar":
			return _ac_atacar(db, state, acao)
		"encerrar_turno":
			_finalizar_turno(db, state)
			return true
	push_error("Ação desconhecida: %s" % acao["tipo"])
	return false


static func _ac_posicionar_ativo(db: CardDB, state: Dictionary, acao: Dictionary) -> bool:
	var p := jogador(state, acao["lado"])
	var id: String = p["mao"].pop_at(acao["indice_mao"])
	p["ativo"] = nova_besta(db, id, 0)
	_log(state, "Jogador %d posiciona %s como Ativo." % [acao["lado"], db.get_card(id)["nome"]])
	# Quando ambos posicionaram, a batalha começa.
	if state["jogadores"][0]["ativo"] != null and state["jogadores"][1]["ativo"] != null:
		state["fase"] = "jogando"
		state["jogador_atual"] = state["primeiro_jogador"]
		_iniciar_turno(db, state)
	return true


static func _ac_colocar_reserva(db: CardDB, state: Dictionary, acao: Dictionary) -> bool:
	var p := jogador(state, state["jogador_atual"])
	if (p["reserva"] as Array).size() >= LIMITE_RESERVA:
		return false
	var id: String = p["mao"].pop_at(acao["indice_mao"])
	p["reserva"].append(nova_besta(db, id, state["turno"]))
	_log(state, "%s entra na Reserva." % db.get_card(id)["nome"])
	return true


static func _ac_evoluir(db: CardDB, state: Dictionary, acao: Dictionary) -> bool:
	var lado: int = state["jogador_atual"]
	var p := jogador(state, lado)
	var besta: Dictionary = besta_em(state, lado, acao["alvo"])
	var id: String = p["mao"][acao["indice_mao"]]
	var card := db.get_card(id)
	if besta == null or not _pode_evoluir(state, besta, card, state["turno"]):
		return false
	p["mao"].remove_at(acao["indice_mao"])
	besta["pilha"].append(id)
	besta["carta"] = id
	besta["evoluiu_no_turno"] = state["turno"]
	curar_status(besta)  # evoluir cura condições especiais (1.6)
	besta["buffs"] = []
	_log(state, "%s evolui para %s." % [db.get_card(card["evolui_de"])["nome"], card["nome"]])
	# Gatilho de evolução (Correnteza)
	var hab: Variant = card.get("habilidade")
	if hab != null and hab["modo"] == "gatilho_evoluir" and acao.get("usar_gatilho", false):
		Effects.executar(db, state, lado, hab["efeitos"], {"params": acao.get("params", {})})
		_processar_nocautes(db, state)
	return true


static func _ac_anexar_mana(db: CardDB, state: Dictionary, acao: Dictionary) -> bool:
	var lado: int = state["jogador_atual"]
	var p := jogador(state, lado)
	if p["mana_atual"] == "" or p["mana_anexada"]:
		return false
	var besta: Dictionary = besta_em(state, lado, acao["alvo"])
	if besta == null:
		return false
	besta["energias"].append(p["mana_atual"])
	_log(state, "Mana %s anexada a %s." % [p["mana_atual"], carta_de(db, besta)["nome"]])
	p["mana_atual"] = ""
	p["mana_anexada"] = true
	return true


static func _ac_anexar_ferramenta(db: CardDB, state: Dictionary, acao: Dictionary) -> bool:
	var lado: int = state["jogador_atual"]
	var p := jogador(state, lado)
	var besta: Dictionary = besta_em(state, lado, acao["alvo"])
	if besta == null or besta["ferramenta"] != null:
		return false
	var id: String = p["mao"].pop_at(acao["indice_mao"])
	besta["ferramenta"] = id
	_log(state, "%s anexada a %s." % [db.get_card(id)["nome"], carta_de(db, besta)["nome"]])
	return true


static func _ac_jogar_aliado(db: CardDB, state: Dictionary, acao: Dictionary) -> bool:
	var lado: int = state["jogador_atual"]
	var p := jogador(state, lado)
	var id: String = p["mao"][acao["indice_mao"]]
	var card := db.get_card(id)
	if card["categoria"] == "mentor":
		if p["mentor_jogado"]:
			return false
		p["mentor_jogado"] = true
	p["mao"].remove_at(acao["indice_mao"])
	p["descarte"].append(id)
	_log(state, "Jogador %d joga %s." % [lado, card["nome"]])
	Effects.executar(db, state, lado, card["efeitos"], {"params": acao.get("params", {})})
	_processar_nocautes(db, state)
	return true


static func _ac_usar_habilidade(db: CardDB, state: Dictionary, acao: Dictionary) -> bool:
	var lado: int = state["jogador_atual"]
	var besta: Dictionary = besta_em(state, lado, acao["alvo"])
	if besta == null:
		return false
	var hab: Variant = carta_de(db, besta).get("habilidade")
	if hab == null or hab["modo"] != "ativada" or int(besta["usou_habilidade_no_turno"]) == state["turno"]:
		return false
	besta["usou_habilidade_no_turno"] = state["turno"]
	_log(state, "Habilidade: %s (%s)." % [hab["nome"], carta_de(db, besta)["nome"]])
	Effects.executar(db, state, lado, hab["efeitos"], {"besta": besta, "alvo_pos": acao["alvo"], "params": acao.get("params", {})})
	_processar_nocautes(db, state)
	return true


static func _ac_descartar_reliquia(db: CardDB, state: Dictionary, acao: Dictionary) -> bool:
	var lado: int = state["jogador_atual"]
	var p := jogador(state, lado)
	if p["ativo"] == null or not p["ativo"].get("reliquia", false):
		return false
	_descartar_besta(db, state, lado, p["ativo"])
	p["ativo"] = null
	if (p["reserva"] as Array).is_empty():
		return false  # não pode se descartar sem reposição
	state["fase"] = "promocao"
	state["promocoes_pendentes"] = [lado]
	return true


static func _ac_recuar(db: CardDB, state: Dictionary, acao: Dictionary) -> bool:
	var lado: int = state["jogador_atual"]
	var p := jogador(state, lado)
	if p["recuou"] or p["ativo"] == null:
		return false
	var custo := custo_recuo(db, state, lado)
	if (p["ativo"]["energias"] as Array).size() < custo:
		return false
	for i in custo:
		p["ativo"]["energias"].pop_back()
	_trocar_ativo(state, p, acao["indice_reserva"])
	p["recuou"] = true
	_log(state, "Recuo: %s assume a Linha de Frente." % carta_de(db, p["ativo"])["nome"])
	return true


static func _trocar_ativo(state: Dictionary, p: Dictionary, indice_reserva: int) -> void:
	var novo: Dictionary = p["reserva"].pop_at(indice_reserva)
	var antigo: Dictionary = p["ativo"]
	curar_status(antigo)  # ir para o Banco cura condições (1.6)
	p["reserva"].append(antigo)
	p["ativo"] = novo


static func _ac_promover(db: CardDB, state: Dictionary, acao: Dictionary) -> bool:
	var lado: int = acao["lado"]
	if state["fase"] != "promocao" or state["promocoes_pendentes"][0] != lado:
		return false
	var p := jogador(state, lado)
	p["ativo"] = p["reserva"].pop_at(acao["idx"])
	_log(state, "Jogador %d promove %s." % [lado, carta_de(db, p["ativo"])["nome"]])
	state["promocoes_pendentes"].pop_front()
	if (state["promocoes_pendentes"] as Array).is_empty():
		state["fase"] = "jogando"
		var continuacao: String = state.get("apos_promocao", "")
		state["apos_promocao"] = ""
		match continuacao:
			"finalizar_turno":
				_finalizar_turno(db, state)
			"trocar_jogador":
				_proximo_jogador(db, state)
	return true

# ============================================================ ataque

static func _ac_atacar(db: CardDB, state: Dictionary, acao: Dictionary) -> bool:
	var lado: int = state["jogador_atual"]
	var p := jogador(state, lado)
	var atacante: Dictionary = p["ativo"]
	var card := carta_de(db, atacante)
	var ataque: Dictionary = card["ataques"][acao["indice_ataque"]]
	if not pode_pagar(db, state, lado, atacante, ataque):
		return false
	_log(state, "%s usa %s!" % [card["nome"], ataque["nome"]])

	# Confusão: coroa = falha (1.6)
	if tem_status(atacante, "confuso") and not moeda(state, "confusão"):
		_log(state, "O ataque falhou pela Confusão!")
		_finalizar_turno(db, state)
		return true

	Effects.resolver_ataque(db, state, lado, atacante, ataque, acao.get("params", {}))
	_processar_nocautes(db, state)
	if state["fase"] != "fim":
		if state["fase"] == "promocao":
			state["apos_promocao"] = "finalizar_turno"
		else:
			_finalizar_turno(db, state)
	return true


## Dano de ataque padrão no defensor Ativo (com fraqueza, ferramenta, reduções, Intangível).
static func dano_no_defensor(db: CardDB, state: Dictionary, lado_atacante: int, dano_base: int, ignora_reducao: bool) -> int:
	if dano_base <= 0:
		return 0
	var atacante: Dictionary = jogador(state, lado_atacante)["ativo"]
	var defensor: Dictionary = jogador(state, 1 - lado_atacante)["ativo"]
	var card_atk := carta_de(db, atacante)
	var card_def := carta_de(db, defensor)
	var dano := dano_base

	# Fraqueza +20 (só na Linha de Frente; 1.5)
	if card_def["categoria"] == "besta" and card_def["fraqueza"] != null \
			and card_atk.get("tipo", "") == card_def["fraqueza"]:
		dano += FRAQUEZA_BONUS
		_log(state, "Fraqueza! +%d de dano." % FRAQUEZA_BONUS)

	# Garra Afiada (+10 contra a Linha de Frente)
	if atacante["ferramenta"] != null:
		for ef in db.get_card(atacante["ferramenta"]).get("efeitos", []):
			if ef["bloco"] == "dano_bonus_ferramenta":
				dano += int(ef["valor"])

	# Bônus condicional por habilidade passiva (Manto da Noite)
	var bonus: Variant = habilidade_passiva(db, atacante, "bonus_dano_se")
	if bonus != null and Effects.checar_condicao(db, state, lado_atacante, bonus["condicao"]):
		dano += int(bonus["valor"])

	var ignora_habilidades := habilidade_passiva(db, atacante, "ignora_habilidades_defensor") != null

	# Intangível (Espectrolho): moeda 1x por turno do oponente
	if not ignora_habilidades and habilidade_passiva(db, defensor, "intangivel_moeda") != null \
			and int(defensor["intangivel_no_turno"]) != state["turno"]:
		defensor["intangivel_no_turno"] = state["turno"]
		if moeda(state, "Intangível"):
			_log(state, "Intangível previne todo o dano!")
			return 0

	if not ignora_reducao:
		dano -= reducao_de_dano(db, state, defensor, ignora_habilidades)
	return maxi(dano, 0)


static func reducao_de_dano(db: CardDB, state: Dictionary, besta: Dictionary, ignora_habilidades: bool) -> int:
	var total := 0
	if not ignora_habilidades:
		var red: Variant = habilidade_passiva(db, besta, "reducao_dano")
		if red != null:
			total += int(red["valor"])
	for buff in besta["buffs"]:
		if buff["tipo"] == "reducao_dano" and state["turno"] <= int(buff["ate_turno"]):
			total += int(buff["valor"])
	return total


## Aplica dano direto a uma besta (já modificado). Nocautes são processados depois.
static func causar_dano(db: CardDB, state: Dictionary, besta: Dictionary, dano: int) -> void:
	if dano <= 0:
		return
	besta["dano"] = int(besta["dano"]) + dano
	_log(state, "%s sofre %d de dano (total %d/%d)." % [carta_de(db, besta)["nome"], dano, besta["dano"], ps_total(db, besta)])


static func retaliacao_de(db: CardDB, besta: Dictionary) -> int:
	var total := 0
	var ret: Variant = habilidade_passiva(db, besta, "retaliacao")
	if ret != null:
		total += int(ret["valor"])
	if besta["ferramenta"] != null:
		for ef in db.get_card(besta["ferramenta"]).get("efeitos", []):
			if ef["bloco"] == "retaliacao":
				total += int(ef["valor"])
	return total

# ============================================================ nocautes / vitória

static func _processar_nocautes(db: CardDB, state: Dictionary) -> void:
	if state["fase"] == "fim":
		return
	for lado in 2:
		var p := jogador(state, lado)
		# Reserva primeiro (não gera promoção)
		var vivos: Array = []
		for besta in p["reserva"]:
			if int(besta["dano"]) >= ps_total(db, besta):
				_nocautear(db, state, lado, besta)
			else:
				vivos.append(besta)
		p["reserva"] = vivos
		if p["ativo"] != null and int(p["ativo"]["dano"]) >= ps_total(db, p["ativo"]):
			_nocautear(db, state, lado, p["ativo"])
			p["ativo"] = null
	_checar_vitoria(db, state)
	if state["fase"] == "fim":
		return
	# Promoções pendentes
	var pendentes: Array = []
	for lado in 2:
		if jogador(state, lado)["ativo"] == null:
			pendentes.append(lado)
	if not pendentes.is_empty():
		state["fase"] = "promocao"
		state["promocoes_pendentes"] = pendentes


static func _nocautear(db: CardDB, state: Dictionary, lado: int, besta: Dictionary) -> void:
	var card := carta_de(db, besta)
	_log(state, "%s foi nocauteado!" % card["nome"])
	_descartar_besta(db, state, lado, besta)
	var oponente := jogador(state, 1 - lado)
	var selos := 0
	if card["categoria"] == "besta":
		selos = 2 if card.get("omega", false) else 1
	elif card["categoria"] == "reliquia" and card["reliquia"].get("concede_selo", false):
		selos = 1
	if selos > 0:
		oponente["selos"] = int(oponente["selos"]) + selos
		_log(state, "Jogador %d marca %d selo(s) (total %d)." % [1 - lado, selos, oponente["selos"]])


static func _descartar_besta(db: CardDB, state: Dictionary, lado: int, besta: Dictionary) -> void:
	var p := jogador(state, lado)
	p["descarte"].append_array(besta["pilha"])
	if besta["ferramenta"] != null:
		p["descarte"].append(besta["ferramenta"])


static func _checar_vitoria(db: CardDB, state: Dictionary) -> void:
	var v0 := int(jogador(state, 0)["selos"]) >= SELOS_VITORIA
	var v1 := int(jogador(state, 1)["selos"]) >= SELOS_VITORIA
	# Sem monstros em jogo = derrota (1.5)
	var z0 := bestas_em_jogo(jogador(state, 0)) == 0
	var z1 := bestas_em_jogo(jogador(state, 1)) == 0
	if v0 or z1:
		_terminar(state, 0)
	elif v1 or z0:
		_terminar(state, 1)


static func _terminar(state: Dictionary, vencedor: int) -> void:
	state["fase"] = "fim"
	state["vencedor"] = vencedor
	if vencedor == 2:
		_log(state, "Empate no turno %d." % state["turno"])
	else:
		_log(state, "Jogador %d VENCE!" % vencedor)

# ============================================================ turnos

static func _iniciar_turno(db: CardDB, state: Dictionary) -> void:
	state["turno"] = int(state["turno"]) + 1
	if int(state["turno"]) > TURNO_EMPATE:
		_terminar(state, 2)
		return
	var lado: int = state["jogador_atual"]
	var p := jogador(state, lado)
	p["mana_anexada"] = false
	p["mentor_jogado"] = false
	p["recuou"] = false
	p["buffs"] = {}
	_log(state, "— Turno %d (jogador %d) —" % [state["turno"], lado])

	# Comprar (pulado com 10+ cartas; deck vazio não derrota)
	if (p["mao"] as Array).size() < LIMITE_MAO and not (p["deck"] as Array).is_empty():
		p["mao"].append(p["deck"].pop_front())

	# Mana do Núcleo (quem começa não recebe no 1º turno; 1.2)
	if not (int(state["turno"]) == 1 and lado == int(state["primeiro_jogador"])):
		p["mana_atual"] = p["proxima_mana"]
		var rng := _rng_de(state)
		p["proxima_mana"] = _sortear_mana(p, rng)
		state["rng_state"] = rng.state
	else:
		p["mana_atual"] = ""


static func _finalizar_turno(db: CardDB, state: Dictionary) -> void:
	var lado: int = state["jogador_atual"]
	var p := jogador(state, lado)
	p["mana_atual"] = ""  # mana não usada é perdida

	# Paralisia cura automática ao final do turno do dono (1.6)
	if p["ativo"] != null:
		for s in p["ativo"]["status"].duplicate():
			if s["id"] == "paralisado" and int(s["turno"]) < state["turno"]:
				_remover_status(p["ativo"], "paralisado")
				_log(state, "%s não está mais Paralisado." % carta_de(db, p["ativo"])["nome"])

	_checkup(db, state)
	_processar_nocautes(db, state)
	if state["fase"] == "fim":
		return
	if state["fase"] == "promocao":
		state["apos_promocao"] = "trocar_jogador"
		return
	_proximo_jogador(db, state)


static func _proximo_jogador(db: CardDB, state: Dictionary) -> void:
	state["jogador_atual"] = 1 - int(state["jogador_atual"])
	_iniciar_turno(db, state)


static func _checkup(db: CardDB, state: Dictionary) -> void:
	# Entre os turnos, os Ativos dos dois lados sofrem seus status (1.6).
	for lado in 2:
		var besta: Variant = jogador(state, lado)["ativo"]
		if besta == null:
			continue
		for s in (besta["status"] as Array).duplicate():
			match s["id"]:
				"envenenado":
					causar_dano(db, state, besta, int(s.get("dano", 10)))
				"queimado":
					causar_dano(db, state, besta, 20)
					if moeda(state, "queimadura"):
						_remover_status(besta, "queimado")
						_log(state, "%s não está mais Queimado." % carta_de(db, besta)["nome"])
				"adormecido":
					if moeda(state, "sono"):
						_remover_status(besta, "adormecido")
						_log(state, "%s acordou." % carta_de(db, besta)["nome"])

# ============================================================ util

static func _log(state: Dictionary, msg: String) -> void:
	state["log"].append(msg)
