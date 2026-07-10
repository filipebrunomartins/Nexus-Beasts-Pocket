class_name Missions
extends RefCounted
## Missões diárias (README 7.1): 3 por dia, sorteadas do pool; progresso por
## eventos de jogo; recompensa resgatada na tela de missões.

const POR_DIA := 3
const XP_POR_MISSAO := 30

const POOL := [
	{"tipo": "vencer_batalhas", "alvo": 1, "texto": "Vença 1 batalha", "recompensa": {"moedas": 50}},
	{"tipo": "vencer_batalhas", "alvo": 2, "texto": "Vença 2 batalhas", "recompensa": {"moedas": 80}},
	{"tipo": "abrir_pacotes", "alvo": 1, "texto": "Abra 1 pacote", "recompensa": {"moedas": 40}},
	{"tipo": "causar_dano", "alvo": 200, "texto": "Cause 200 de dano", "recompensa": {"ampulhetas": 1}},
	{"tipo": "causar_dano", "alvo": 400, "texto": "Cause 400 de dano", "recompensa": {"moedas": 70}},
	{"tipo": "vencer_campanha", "alvo": 1, "texto": "Vença 1 desafiante da campanha", "recompensa": {"moedas": 60}},
]


## Garante que as missões são do dia atual; re-sorteia na virada do dia.
static func atualizar_dia(save_dados: Dictionary, hoje: String, rng: RandomNumberGenerator) -> void:
	var missoes: Dictionary = save_dados["missoes"]
	if missoes.get("dia", "") == hoje:
		return
	var indices := range(POOL.size())
	var lista: Array = []
	for i in POR_DIA:
		var j: int = indices[rng.randi_range(0, indices.size() - 1)]
		indices.erase(j)
		var m: Dictionary = (POOL[j] as Dictionary).duplicate(true)
		m["progresso"] = 0
		m["resgatada"] = false
		lista.append(m)
	save_dados["missoes"] = {"dia": hoje, "lista": lista}


## Registra um evento de jogo e avança as missões correspondentes.
static func registrar_evento(save_dados: Dictionary, tipo: String, qtd: int = 1) -> void:
	for m in save_dados["missoes"].get("lista", []):
		if m["tipo"] == tipo and not m["resgatada"]:
			m["progresso"] = mini(int(m["progresso"]) + qtd, int(m["alvo"]))


static func completa(m: Dictionary) -> bool:
	return int(m["progresso"]) >= int(m["alvo"])


## Resgata a recompensa da missão idx. Devolve descrição dos ganhos.
static func resgatar(save_dados: Dictionary, idx: int) -> PackedStringArray:
	var ganhos: PackedStringArray = []
	var lista: Array = save_dados["missoes"].get("lista", [])
	if idx < 0 or idx >= lista.size():
		return ganhos
	var m: Dictionary = lista[idx]
	if m["resgatada"] or not completa(m):
		return ganhos
	m["resgatada"] = true
	var r: Dictionary = m["recompensa"]
	if r.has("moedas"):
		save_dados["moedas"] = int(save_dados["moedas"]) + int(r["moedas"])
		ganhos.append("💰 %d moedas" % r["moedas"])
	if r.has("ampulhetas"):
		save_dados["ampulhetas"] = int(save_dados["ampulhetas"]) + int(r["ampulhetas"])
		ganhos.append("⏳ %d ampulheta" % r["ampulhetas"])
	ganhos.append_array(Progression.ganhar_xp(save_dados, XP_POR_MISSAO))
	return ganhos
