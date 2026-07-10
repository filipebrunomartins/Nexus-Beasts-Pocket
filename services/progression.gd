class_name Progression
extends RefCounted
## Progressão de conta: XP por partida e missão, níveis com recompensa.

const XP_VITORIA := 50
const XP_DERROTA := 20
const MOEDAS_POR_NIVEL := 100


## XP total necessário para ALCANÇAR o nível dado (nível 1 = 0).
static func xp_para_nivel(nivel: int) -> int:
	# subir do nível N para N+1 custa 100 + (N−1)*50
	var total := 0
	for n in range(1, nivel):
		total += 100 + (n - 1) * 50
	return total


static func nivel_de(xp: int) -> int:
	var nivel := 1
	while xp >= xp_para_nivel(nivel + 1):
		nivel += 1
	return nivel


## Credita XP, detecta subida de nível e paga o bônus. Devolve descrições.
static func ganhar_xp(save_dados: Dictionary, xp: int) -> PackedStringArray:
	var ganhos: PackedStringArray = []
	var nivel_antes := nivel_de(int(save_dados["xp"]))
	save_dados["xp"] = int(save_dados["xp"]) + xp
	ganhos.append("✨ +%d XP" % xp)
	var nivel_depois := nivel_de(int(save_dados["xp"]))
	if nivel_depois > nivel_antes:
		var bonus := (nivel_depois - nivel_antes) * MOEDAS_POR_NIVEL
		save_dados["moedas"] = int(save_dados["moedas"]) + bonus
		ganhos.append("🎉 Nível %d! +%d moedas" % [nivel_depois, bonus])
	return ganhos


static func registrar_batalha(save_dados: Dictionary, venceu: bool) -> PackedStringArray:
	return ganhar_xp(save_dados, XP_VITORIA if venceu else XP_DERROTA)
