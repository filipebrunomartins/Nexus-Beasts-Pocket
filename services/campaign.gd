class_name Campaign
extends RefCounted
## Progressão da campanha (README 7.5): desbloqueio sequencial, estrelas de
## desempenho e recompensas de primeira vitória/revanche.

const ARQUIVO := "res://data/campaign.json"
const RECOMPENSA_REVANCHE := {"moedas": 20}
const TURNOS_PARA_3_ESTRELAS := 12


static func carregar() -> Array:
	var file := FileAccess.open(ARQUIVO, FileAccess.READ)
	var dados: Dictionary = JSON.parse_string(file.get_as_text())
	return dados["mapas"]


static func mapa_desbloqueado(save_dados: Dictionary, mapas: Array, idx: int) -> bool:
	if idx == 0:
		return true
	var guardiao: Dictionary = mapas[idx - 1]["desafiantes"][-1]
	return venceu(save_dados, guardiao["id"])


static func desafiante_desbloqueado(save_dados: Dictionary, mapa: Dictionary, idx: int) -> bool:
	if idx == 0:
		return true
	return venceu(save_dados, mapa["desafiantes"][idx - 1]["id"])


static func venceu(save_dados: Dictionary, desafiante_id: String) -> bool:
	return save_dados["campanha"]["vencidos"].get(desafiante_id, false)


static func estrelas(save_dados: Dictionary, desafiante_id: String) -> int:
	return int(save_dados["campanha"]["estrelas"].get(desafiante_id, 0))


static func vitorias_no_mapa(save_dados: Dictionary, mapa: Dictionary) -> int:
	var total := 0
	for d in mapa["desafiantes"]:
		if venceu(save_dados, d["id"]):
			total += 1
	return total


## Marcos de estrelas por mapa que liberam pacotes bônus (7.5.6).
const MARCOS_ESTRELAS := [6, 12, 18]


static func estrelas_do_mapa(save_dados: Dictionary, mapa: Dictionary) -> int:
	var total := 0
	for d in mapa["desafiantes"]:
		total += estrelas(save_dados, d["id"])
	return total


## Resgata automaticamente marcos de estrelas atingidos. Devolve nº de pacotes ganhos.
static func resgatar_marcos(save_dados: Dictionary, mapa: Dictionary) -> int:
	var camp: Dictionary = save_dados["campanha"]
	if not camp.has("marcos"):
		camp["marcos"] = {}
	var resgatados: Array = camp["marcos"].get(mapa["id"], [])
	var total := estrelas_do_mapa(save_dados, mapa)
	var ganhos := 0
	for marco in MARCOS_ESTRELAS:
		if total >= marco and not resgatados.has(marco):
			resgatados.append(marco)
			ganhos += 1
	if ganhos > 0:
		camp["marcos"][mapa["id"]] = resgatados
		save_dados["pacotes_bonus"] = int(save_dados.get("pacotes_bonus", 0)) + ganhos
	return ganhos


## Estrelas da batalha: vencer / sem perder Besta / em até 12 turnos (7.5.6).
static func calcular_estrelas(venceu_: bool, selos_oponente: int, turnos: int) -> int:
	if not venceu_:
		return 0
	var e := 1
	if selos_oponente == 0:
		e += 1
	if turnos <= TURNOS_PARA_3_ESTRELAS:
		e += 1
	return e


## Registra o resultado e aplica recompensas. Devolve descrição do que foi ganho.
static func registrar_resultado(save_dados: Dictionary, desafiante: Dictionary,
		venceu_: bool, selos_oponente: int, turnos: int) -> PackedStringArray:
	var ganhos: PackedStringArray = []
	if not venceu_:
		return ganhos
	var id: String = desafiante["id"]
	var primeira: bool = not venceu(save_dados, id)
	var estrelas_novas := calcular_estrelas(venceu_, selos_oponente, turnos)
	save_dados["campanha"]["vencidos"][id] = true
	if estrelas_novas > estrelas(save_dados, id):
		save_dados["campanha"]["estrelas"][id] = estrelas_novas

	var recompensa: Dictionary = desafiante["recompensa"] if primeira else RECOMPENSA_REVANCHE
	if recompensa.has("moedas"):
		save_dados["moedas"] = int(save_dados["moedas"]) + int(recompensa["moedas"])
		ganhos.append("💰 %d moedas" % recompensa["moedas"])
	if recompensa.has("ampulhetas"):
		save_dados["ampulhetas"] = int(save_dados["ampulhetas"]) + int(recompensa["ampulhetas"])
		ganhos.append("⏳ %d ampulhetas" % recompensa["ampulhetas"])
	if recompensa.has("pacotes"):
		save_dados["pacotes_bonus"] = int(save_dados.get("pacotes_bonus", 0)) + int(recompensa["pacotes"])
		ganhos.append("🎁 %d pacote bônus" % recompensa["pacotes"])
	if recompensa.has("carta"):
		save_dados["colecao"][recompensa["carta"]] = int(save_dados["colecao"].get(recompensa["carta"], 0)) + 1
		ganhos.append("🎴 carta promocional!")
	if recompensa.has("titulo") and not (save_dados["titulos"] as Array).has(recompensa["titulo"]):
		save_dados["titulos"].append(recompensa["titulo"])
		ganhos.append("👑 título \"%s\"" % recompensa["titulo"])
	return ganhos
