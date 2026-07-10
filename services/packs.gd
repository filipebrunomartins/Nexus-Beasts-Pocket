class_name PackSystem
extends RefCounted
## Sistema de pacotes (README 7.1): 1 pacote grátis a cada 12h, 5 cartas,
## raridade sorteada por slot. Ampulhetas de Mana reduzem 1h do timer.

const INTERVALO_SEG := 12 * 3600
const CARTAS_POR_PACOTE := 5
const AMPULHETA_SEG := 3600

## Pesos de raridade por slot (1-based). Slots 1–3 comuns; 4 melhora; 5 decide.
const PESOS_POR_SLOT := [
	{1: 100},
	{1: 100},
	{1: 60, 2: 40},
	{2: 75, 3: 25},
	{2: 40, 3: 42, 4: 18},
]


static func pode_abrir(save_dados: Dictionary, agora: int) -> bool:
	return agora >= int(save_dados["prox_pacote_ts"])


static func segundos_restantes(save_dados: Dictionary, agora: int) -> int:
	return maxi(int(save_dados["prox_pacote_ts"]) - agora, 0)


static func usar_ampulheta(save_dados: Dictionary) -> bool:
	if int(save_dados["ampulhetas"]) <= 0:
		return false
	save_dados["ampulhetas"] = int(save_dados["ampulhetas"]) - 1
	save_dados["prox_pacote_ts"] = int(save_dados["prox_pacote_ts"]) - AMPULHETA_SEG
	return true


## Sorteia as 5 cartas do pacote e atualiza o timer. Não salva — o chamador salva.
static func abrir(db: CardDB, save_dados: Dictionary, agora: int, rng: RandomNumberGenerator) -> Array:
	var por_raridade := _cartas_por_raridade(db)
	var cartas: Array = []
	for slot in CARTAS_POR_PACOTE:
		var raridade := _sortear_raridade(PESOS_POR_SLOT[slot], rng)
		# fallback: se não houver carta da raridade, desce até achar
		while raridade > 1 and not por_raridade.has(raridade):
			raridade -= 1
		var lista: Array = por_raridade[raridade]
		cartas.append(lista[rng.randi_range(0, lista.size() - 1)])
	save_dados["prox_pacote_ts"] = agora + INTERVALO_SEG
	save_dados["pacotes_abertos"] = int(save_dados.get("pacotes_abertos", 0)) + 1
	return cartas


static func _sortear_raridade(pesos: Dictionary, rng: RandomNumberGenerator) -> int:
	var total := 0
	for r in pesos:
		total += int(pesos[r])
	var sorteio := rng.randi_range(1, total)
	var acumulado := 0
	for r in pesos:
		acumulado += int(pesos[r])
		if sorteio <= acumulado:
			return int(r)
	return 1


static func _cartas_por_raridade(db: CardDB) -> Dictionary:
	var mapa := {}
	for card in db.all_cards():
		var r := int(card.get("raridade", 1))
		if not mapa.has(r):
			mapa[r] = []
		mapa[r].append(card["id"])
	return mapa


## Probabilidades por slot em texto (transparência exigida na seção 7.7).
static func tabela_probabilidades() -> String:
	var nomes := {1: "♦1", 2: "♦2", 3: "♦3", 4: "♦4 (Ω)"}
	var linhas: PackedStringArray = []
	for slot in PESOS_POR_SLOT.size():
		var pesos: Dictionary = PESOS_POR_SLOT[slot]
		var total := 0
		for r in pesos:
			total += int(pesos[r])
		var partes: PackedStringArray = []
		for r in pesos:
			partes.append("%s %d%%" % [nomes[int(r)], 100 * int(pesos[r]) / total])
		linhas.append("Carta %d: %s" % [slot + 1, " · ".join(partes)])
	return "\n".join(linhas)
