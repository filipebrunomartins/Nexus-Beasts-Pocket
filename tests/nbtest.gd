class_name NBTest
extends RefCounted
## Base dos testes headless: asserts que acumulam falhas em vez de abortar.

var falhas: PackedStringArray = []
var db: CardDB


func antes() -> void:
	if db == null:
		db = CardDB.load_default()


func ok(cond: bool, msg: String) -> void:
	if not cond:
		falhas.append(msg)


func igual(obtido: Variant, esperado: Variant, msg: String) -> void:
	if obtido != esperado:
		falhas.append("%s (esperado %s, obtido %s)" % [msg, esperado, obtido])

# ------------------------------------------------ fixtures de partida

## Partida real com os decks da Parte 5, setup resolvido. Jogador 0 começa.
func partida(seed_: int = 42) -> Dictionary:
	var decks := CardDB.load_decks()
	var state := Rules.nova_partida(db, decks[0]["cartas"], decks[1]["cartas"],
			decks[0]["tipos_mana"], decks[1]["tipos_mana"], seed_, 0)
	while state["fase"] == "setup":
		Rules.aplicar(db, state, Rules.acoes_legais(db, state)[0])
	return state


## Cenário controlado: ativos definidos à mão, turno adiantado (sem restrições
## de 1º turno), jogador 0 na vez, sem mana pendente.
func cenario(carta0: String, carta1: String, seed_: int = 42) -> Dictionary:
	var state := partida(seed_)
	state["turno"] = 5
	state["jogador_atual"] = 0
	state["fase"] = "jogando"
	state["promocoes_pendentes"] = []
	for lado in 2:
		var p: Dictionary = state["jogadores"][lado]
		p["ativo"] = Rules.nova_besta(db, [carta0, carta1][lado], 0)
		p["reserva"] = []
		p["mana_atual"] = ""
		p["mana_anexada"] = false
		p["mentor_jogado"] = false
		p["recuou"] = false
		p["selos"] = 0
	return state


## Anexa energias a uma besta diretamente.
func energizar(besta: Dictionary, tipos: Array) -> void:
	besta["energias"].append_array(tipos)


## Coloca uma besta na reserva do lado indicado.
func reservar(state: Dictionary, lado: int, carta: String) -> Dictionary:
	var besta := Rules.nova_besta(db, carta, 0)
	state["jogadores"][lado]["reserva"].append(besta)
	return besta


## Executa a primeira ação legal que casa com o filtro.
func agir(state: Dictionary, filtro: Dictionary) -> bool:
	var acao := achar_acao(state, filtro)
	if acao.is_empty():
		falhas.append("Ação não encontrada: %s" % str(filtro))
		return false
	return Rules.aplicar(db, state, acao)


func achar_acao(state: Dictionary, filtro: Dictionary) -> Dictionary:
	for acao in Rules.acoes_legais(db, state):
		var casa := true
		for k in filtro:
			if not acao.has(k) or acao[k] != filtro[k]:
				casa = false
				break
		if casa:
			return acao
	return {}


func tem_acao(state: Dictionary, filtro: Dictionary) -> bool:
	return not achar_acao(state, filtro).is_empty()
