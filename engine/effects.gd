class_name Effects
extends RefCounted
## Interpretador dos blocos de efeito das cartas (README 7.4).
## Cada efeito é {"bloco": nome, ...params}. As cartas são dados; este
## vocabulário fixo de blocos é o único código que "entende" efeitos.

# ============================================================ resolução de ataque

static func resolver_ataque(db: CardDB, state: Dictionary, lado: int, atacante: Dictionary, ataque: Dictionary, params: Dictionary) -> void:
	var defensor: Dictionary = Rules.jogador(state, 1 - lado)["ativo"]
	var dano_base := int(ataque["dano"])
	var ignora_reducao := false
	var pos_efeitos: Array = []

	# 1) Modificadores de dano
	for ef in ataque["efeitos"]:
		match ef["bloco"]:
			"moedas_dano":
				for i in int(ef["qtd"]):
					if Rules.moeda(state, ataque["nome"]):
						dano_base += int(ef["dano_por_cara"])
			"dano_bonus_se":
				if checar_condicao(db, state, lado, ef["condicao"]):
					dano_base += int(ef["valor"])
			"dano_por_energia_extra":
				dano_base += int(ef["valor"]) * _energias_extras(atacante, ataque, ef["tipo"])
			"ignorar_reducao":
				ignora_reducao = true
			_:
				pos_efeitos.append(ef)

	# 2) Dano principal no defensor
	var dano_causado := 0
	var nocauteou := false
	if dano_base > 0:
		dano_causado = Rules.dano_no_defensor(db, state, lado, dano_base, ignora_reducao)
		Rules.causar_dano(db, state, defensor, dano_causado)
		nocauteou = int(defensor["dano"]) >= Rules.ps_total(db, defensor)
		# 3) Retaliação (Casca de Espinhos / Manto Espinhoso)
		if dano_causado > 0:
			var ret := Rules.retaliacao_de(db, defensor)
			if ret > 0 and Rules.habilidade_passiva(db, atacante, "ignora_habilidades_defensor") == null:
				Rules.causar_dano(db, state, atacante, ret)

	# 4) Efeitos pós-dano
	var ctx := {
		"besta": atacante,
		"defensor": defensor,
		"nocauteou": nocauteou,
		"dano_causado": dano_causado,
		"params": params,
	}
	executar(db, state, lado, pos_efeitos, ctx)


static func _energias_extras(besta: Dictionary, ataque: Dictionary, tipo: String) -> int:
	# "+X por energia <tipo> além do custo": energias do tipo que sobram depois
	# de pagar os custos tipados e os slots ⭐ não cobertos por outras energias.
	var custo: Array = ataque["custo"]
	var tipado := custo.count(tipo)
	var qualquer := custo.count("qualquer")
	var do_tipo := (besta["energias"] as Array).count(tipo)
	var outras := (besta["energias"] as Array).size() - do_tipo
	var outras_livres := outras - (custo.size() - tipado - qualquer)
	var qualquer_pago_com_tipo := maxi(qualquer - maxi(outras_livres, 0), 0)
	return maxi(do_tipo - tipado - qualquer_pago_com_tipo, 0)

# ============================================================ execução de blocos

static func executar(db: CardDB, state: Dictionary, lado: int, efeitos: Array, ctx: Dictionary) -> void:
	var p := Rules.jogador(state, lado)
	var op := Rules.jogador(state, 1 - lado)
	var params: Dictionary = ctx.get("params", {})
	for ef in efeitos:
		match ef["bloco"]:
			"moeda":
				var ramo: Array = ef.get("se_cara", []) if Rules.moeda(state) else ef.get("se_coroa", [])
				executar(db, state, lado, ramo, ctx)

			"status":
				var alvo: Variant = op["ativo"]
				if alvo != null and int(alvo["dano"]) < Rules.ps_total(db, alvo) \
						and not _imune_a(db, alvo, ef["status"]):
					Rules.aplicar_status(state, alvo, ef["status"], int(ef.get("dano_checkup", 0)))
					Rules._log(state, "%s ficou %s." % [Rules.carta_de(db, alvo)["nome"], ef["status"].capitalize()])

			"curar":
				var alvo: Variant
				match ef.get("alvo", "self"):
					"self":
						alvo = ctx.get("besta")
					"escolha_proprio":
						alvo = Rules.besta_em(state, lado, params.get("alvo_proprio", {"pos": "ativo"}))
					"linha_frente_propria":
						alvo = p["ativo"]
				if alvo != null:
					var antes := int(alvo["dano"])
					alvo["dano"] = maxi(antes - int(ef["valor"]), 0)
					Rules._log(state, "%s cura %d." % [Rules.carta_de(db, alvo)["nome"], antes - int(alvo["dano"])])

			"auto_dano":
				Rules.causar_dano(db, state, ctx["besta"], int(ef["valor"]))

			"descartar_energia_self":
				var besta: Dictionary = ctx["besta"]
				for i in int(ef["qtd"]):
					var idx: int = besta["energias"].find(ef["tipo"])
					if idx < 0 and not (besta["energias"] as Array).is_empty():
						idx = 0
					if idx >= 0:
						besta["energias"].remove_at(idx)

			"devolver_energia_defensor":
				var alvo: Variant = op["ativo"]
				if alvo != null:
					for i in int(ef.get("qtd", 1)):
						if not (alvo["energias"] as Array).is_empty():
							alvo["energias"].pop_back()
							Rules._log(state, "Energia devolvida ao Núcleo do oponente.")

			"dano_alvo_escolha":
				# Dano de efeito em alvo escolhido (Reserva incluída): sem fraqueza (1.5).
				var pos: Dictionary = params.get("alvo_oponente", {"pos": "ativo"})
				var alvo: Variant = Rules.besta_em(state, 1 - lado, pos)
				if alvo != null:
					var dano := int(ef["valor"]) - Rules.reducao_de_dano(db, state, alvo, false)
					Rules.causar_dano(db, state, alvo, maxi(dano, 0))

			"dano_reserva_propria":
				for besta in p["reserva"]:
					Rules.causar_dano(db, state, besta, int(ef["valor"]))

			"bloquear_recuo_defensor":
				if op["ativo"] != null:
					op["ativo"]["nao_recua_ate"] = int(state["turno"]) + 1

			"bloquear_ataque_defensor":
				if op["ativo"] != null:
					op["ativo"]["nao_ataca_ate"] = int(state["turno"]) + 1

			"bloquear_proprio_ataque":
				ctx["besta"]["nao_ataca_ate"] = int(state["turno"]) + 2

			"reduzir_dano_self":
				ctx["besta"]["buffs"].append({"tipo": "reducao_dano", "valor": int(ef["valor"]), "ate_turno": int(state["turno"]) + 1})

			"comprar_se_nocaute":
				if ctx.get("nocauteou", false):
					_comprar(state, p, int(ef["qtd"]))

			"comprar":
				_comprar(state, p, int(ef["qtd"]))

			"descartar_mao_comprar":
				p["descarte"].append_array(p["mao"])
				p["mao"] = []
				_comprar(state, p, int(ef["qtd"]))

			"buscar_basico":
				var basicos: Array = []
				for i in (p["deck"] as Array).size():
					if CardDB.is_basic_beast(db.get_card(p["deck"][i])):
						basicos.append(i)
				if not basicos.is_empty():
					var escolhido: int = basicos[Rules._rand_int(state, basicos.size())]
					var id: String = p["deck"].pop_at(escolhido)
					if (p["mao"] as Array).size() < Rules.LIMITE_MAO:
						p["mao"].append(id)
						Rules._log(state, "%s vai para a mão." % db.get_card(id)["nome"])
					else:
						p["deck"].append(id)
					_reembaralhar_deck(state, p)

			"gust_oponente":
				# O oponente escolhe quem entra; sem interação, escolhe aleatório.
				if not (op["reserva"] as Array).is_empty() and op["ativo"] != null:
					var idx := Rules._rand_int(state, (op["reserva"] as Array).size())
					Rules._trocar_ativo(state, op, idx)
					Rules._log(state, "%s é puxado para a Linha de Frente!" % Rules.carta_de(db, op["ativo"])["nome"])

			"anexar_mana_nucleo":
				var alvo: Variant
				match ef.get("alvo", "self"):
					"self":
						alvo = ctx.get("besta")
					"reserva_tipo":
						var pos: Dictionary = params.get("alvo_proprio", {})
						alvo = Rules.besta_em(state, lado, pos) if not pos.is_empty() else null
						if alvo == null:
							for besta in p["reserva"]:
								if Rules.carta_de(db, besta).get("tipo", "") == ef.get("tipo_alvo", ""):
									alvo = besta
									break
				if alvo != null:
					for i in int(ef.get("qtd", 1)):
						alvo["energias"].append(ef["tipo"])
					Rules._log(state, "%d energia(s) %s anexada(s) do Núcleo a %s." % [int(ef.get("qtd", 1)), ef["tipo"], Rules.carta_de(db, alvo)["nome"]])

			"olhar_topo":
				var qtd := mini(int(ef["qtd"]), (p["deck"] as Array).size())
				var topo: Array = (p["deck"] as Array).slice(0, qtd)
				state["revelado"] = {"lado": lado, "cartas": topo.duplicate()}
				if ef.get("reordenar", false) and params.has("ordem"):
					var nova: Array = []
					for j in params["ordem"]:
						nova.append(topo[j])
					for j in qtd:
						p["deck"][j] = nova[j]
				Rules._log(state, "Topo do baralho revelado (%d carta(s))." % qtd)

			"mover_energia":
				var origem: Variant = Rules.besta_em(state, lado, params.get("origem", {"pos": "ativo"}))
				var destino: Variant = Rules.besta_em(state, lado, params.get("destino", {"pos": "ativo"}))
				if origem != null and destino != null and origem != destino:
					var idx: int = origem["energias"].find(ef["tipo"])
					if idx >= 0:
						origem["energias"].remove_at(idx)
						destino["energias"].append(ef["tipo"])
						Rules._log(state, "Energia %s movida." % ef["tipo"])

			"reduzir_recuo_lf":
				p["buffs"]["reducao_recuo"] = int(p["buffs"].get("reducao_recuo", 0)) + int(ef["qtd"])

			"remover_status":
				if p["ativo"] != null:
					Rules.curar_status(p["ativo"])
					Rules._log(state, "Condições removidas de %s." % Rules.carta_de(db, p["ativo"])["nome"])

			"switch_proprio":
				if not (p["reserva"] as Array).is_empty() and p["ativo"] != null:
					var idx := int(params.get("indice_reserva", 0))
					Rules._trocar_ativo(state, p, idx)
					Rules._log(state, "%s assume a Linha de Frente." % Rules.carta_de(db, p["ativo"])["nome"])

			"reducao_dano_temporaria":
				var alvo: Variant = Rules.besta_em(state, lado, params.get("alvo_proprio", {"pos": "ativo"}))
				if alvo != null and Rules.carta_de(db, alvo).get("tipo", "") == ef.get("tipo_alvo", Rules.carta_de(db, alvo).get("tipo", "")):
					alvo["buffs"].append({"tipo": "reducao_dano", "valor": int(ef["valor"]), "ate_turno": int(state["turno"]) + 1})

			"ps_bonus", "dano_bonus_ferramenta", "retaliacao", "reducao_dano", "imune_status", \
			"custo_reduzido_se", "recuo_zero_se", "bonus_dano_se", "ignora_habilidades_defensor", \
			"intangivel_moeda":
				pass  # passivos: consultados pelo motor, não executados

			_:
				push_warning("Bloco de efeito não implementado: %s" % ef["bloco"])


static func _imune_a(db: CardDB, besta: Dictionary, status: String) -> bool:
	var imune: Variant = Rules.habilidade_passiva(db, besta, "imune_status")
	return imune != null and (imune["lista"] as Array).has(status)


static func _comprar(state: Dictionary, p: Dictionary, qtd: int) -> void:
	for i in qtd:
		if (p["deck"] as Array).is_empty() or (p["mao"] as Array).size() >= Rules.LIMITE_MAO:
			return
		p["mao"].append(p["deck"].pop_front())


static func _reembaralhar_deck(state: Dictionary, p: Dictionary) -> void:
	var rng := Rules._rng_de(state)
	Rules._embaralhar(p["deck"], rng)
	state["rng_state"] = rng.state


static func checar_condicao(db: CardDB, state: Dictionary, lado: int, condicao: String) -> bool:
	var op := Rules.jogador(state, 1 - lado)
	match condicao:
		"defensor_adormecido":
			return op["ativo"] != null and Rules.tem_status(op["ativo"], "adormecido")
		"defensor_envenenado":
			return op["ativo"] != null and Rules.tem_status(op["ativo"], "envenenado")
		"menos_selos":
			return int(Rules.jogador(state, lado)["selos"]) < int(op["selos"])
	return false

# ============================================================ enumeração de ações (com alvos)

## Ações possíveis ao jogar um Mentor/Item, uma por combinação de alvos.
static func acoes_de_aliado(db: CardDB, state: Dictionary, lado: int, indice_mao: int, card: Dictionary) -> Array:
	var base := {"tipo": "jogar_aliado", "indice_mao": indice_mao}
	var p := Rules.jogador(state, lado)
	var op := Rules.jogador(state, 1 - lado)
	for ef in card.get("efeitos", []):
		match ef["bloco"]:
			"curar":
				if ef.get("alvo") == "escolha_proprio":
					var acoes: Array = []
					for pos in Rules._todas_posicoes(p):
						var besta: Dictionary = Rules.besta_em(state, lado, pos)
						if int(besta["dano"]) > 0:
							acoes.append(_com_params(base, {"alvo_proprio": pos}))
					return acoes if not acoes.is_empty() else [base]
			"gust_oponente":
				return [base] if not (op["reserva"] as Array).is_empty() else []
			"switch_proprio":
				var acoes: Array = []
				for i in (p["reserva"] as Array).size():
					acoes.append(_com_params(base, {"indice_reserva": i}))
				return acoes
			"reducao_dano_temporaria":
				var acoes: Array = []
				for pos in Rules._todas_posicoes(p):
					var besta: Dictionary = Rules.besta_em(state, lado, pos)
					if Rules.carta_de(db, besta).get("tipo", "") == ef.get("tipo_alvo", ""):
						acoes.append(_com_params(base, {"alvo_proprio": pos}))
				return acoes
			"moeda":
				# Suri/Cápsula: alvo dentro do ramo se_cara
				for sub in ef.get("se_cara", []):
					if sub["bloco"] == "anexar_mana_nucleo" and sub.get("alvo") == "reserva_tipo":
						var acoes: Array = []
						for i in (p["reserva"] as Array).size():
							var besta: Dictionary = p["reserva"][i]
							if Rules.carta_de(db, besta).get("tipo", "") == sub.get("tipo_alvo", ""):
								acoes.append(_com_params(base, {"alvo_proprio": {"pos": "reserva", "idx": i}}))
						return acoes
	return [base]


## Ações de habilidade ativada de uma besta (se disponível neste turno).
static func acoes_de_habilidade(db: CardDB, state: Dictionary, lado: int, pos: Dictionary, besta: Dictionary) -> Array:
	var card := Rules.carta_de(db, besta)
	var hab: Variant = card.get("habilidade")
	if hab == null or hab["modo"] != "ativada" or int(besta["usou_habilidade_no_turno"]) == int(state["turno"]):
		return []
	var base := {"tipo": "usar_habilidade", "alvo": pos}
	var p := Rules.jogador(state, lado)
	for ef in hab["efeitos"]:
		match ef["bloco"]:
			"curar":
				return [base] if int(besta["dano"]) > 0 else []
			"reduzir_recuo_lf":
				if ef.get("requer_posicao", "") == "reserva" and pos["pos"] != "reserva":
					return []
				return [base] if p["ativo"] != null else []
			"mover_energia":
				var acoes: Array = []
				for origem in Rules._todas_posicoes(p):
					var b_origem: Dictionary = Rules.besta_em(state, lado, origem)
					if not (b_origem["energias"] as Array).has(ef["tipo"]):
						continue
					for destino in Rules._todas_posicoes(p):
						if origem != destino:
							acoes.append(_com_params(base, {"origem": origem, "destino": destino}))
				return acoes
	return [base]


## Ações de um ataque (uma por alvo, quando o ataque exige escolha).
static func acoes_de_ataque(db: CardDB, state: Dictionary, lado: int, indice_ataque: int, ataque: Dictionary) -> Array:
	var base := {"tipo": "atacar", "indice_ataque": indice_ataque}
	var p := Rules.jogador(state, lado)
	var op := Rules.jogador(state, 1 - lado)
	for ef in ataque["efeitos"]:
		match ef["bloco"]:
			"dano_alvo_escolha":
				var acoes: Array = []
				for pos in Rules._todas_posicoes(op):
					acoes.append(_com_params(base, {"alvo_oponente": pos}))
				return acoes
			"curar":
				if ef.get("alvo") == "escolha_proprio":
					var acoes: Array = []
					for pos in Rules._todas_posicoes(p):
						acoes.append(_com_params(base, {"alvo_proprio": pos}))
					return acoes
	return [base]


static func _com_params(base: Dictionary, params: Dictionary) -> Dictionary:
	var acao := base.duplicate(true)
	acao["params"] = params
	return acao
