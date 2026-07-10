extends SceneTree
## Simulador IA vs IA — valida regras de ponta a ponta e mede balanceamento.
##   godot --headless -s tools/simulate.gd -- [n_partidas] [seed] [nivel_ia] [nivel_ia_b]
## nivel_ia_b (opcional): nível do jogador 1, para medir força entre níveis.
## Métricas-alvo (Parte 6.2): 10–25 turnos, quem começa vence 45–55%.

const MAX_PASSOS_POR_PARTIDA := 3000


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var n := int(args[0]) if args.size() > 0 else 500
	var base_seed := int(args[1]) if args.size() > 1 else 12345
	var nivel := int(args[2]) if args.size() > 2 else 1
	var nivel_b := int(args[3]) if args.size() > 3 else nivel

	var db := CardDB.load_default()
	var decks := CardDB.load_decks()
	var nomes: Array = [decks[0]["nome"], decks[1]["nome"]]

	var vitorias := [0, 0]
	var empates := 0
	var vitorias_de_quem_comeca := 0
	var partidas_decididas := 0
	var total_turnos := 0
	var travadas := 0
	var turnos_min := 9999
	var turnos_max := 0

	var inicio := Time.get_ticks_msec()
	for i in n:
		var primeiro := i % 2  # alterna quem começa
		var state := Rules.nova_partida(db, decks[0]["cartas"], decks[1]["cartas"],
				decks[0]["tipos_mana"], decks[1]["tipos_mana"], base_seed + i, primeiro)
		var ias: Array = [
			HeuristicAI.new(nivel, base_seed * 7 + i * 2 + 1),
			HeuristicAI.new(nivel_b, base_seed * 11 + i * 2 + 2),
		]
		var passos := 0
		while state["fase"] != "fim" and passos < MAX_PASSOS_POR_PARTIDA:
			var lado := MatchRunner.lado_agindo(state)
			var acao: Dictionary = ias[lado].escolher(db, state, lado)
			if acao.is_empty() or not Rules.aplicar(db, state, acao):
				printerr("Partida %d: ação inválida %s — abortando" % [i, str(acao)])
				travadas += 1
				break
			passos += 1
		if passos >= MAX_PASSOS_POR_PARTIDA:
			printerr("Partida %d: excedeu %d passos (possível loop)" % [i, MAX_PASSOS_POR_PARTIDA])
			travadas += 1
			continue
		if state["fase"] != "fim":
			continue

		var turnos := int(state["turno"])
		total_turnos += turnos
		turnos_min = mini(turnos_min, turnos)
		turnos_max = maxi(turnos_max, turnos)
		match int(state["vencedor"]):
			2:
				empates += 1
			_:
				var v := int(state["vencedor"])
				vitorias[v] += 1
				partidas_decididas += 1
				if v == primeiro:
					vitorias_de_quem_comeca += 1

	var dur := (Time.get_ticks_msec() - inicio) / 1000.0
	var completas := n - travadas
	print("================= RELATÓRIO DE SIMULAÇÃO =================")
	print("Partidas: %d (IA nível %d × nível %d, seed %d) em %.1fs" % [n, nivel, nivel_b, base_seed, dur])
	print("Travadas/abortadas: %d" % travadas)
	if completas > 0:
		print("%s: %d vitórias (%.1f%%)" % [nomes[0], vitorias[0], 100.0 * vitorias[0] / completas])
		print("%s: %d vitórias (%.1f%%)" % [nomes[1], vitorias[1], 100.0 * vitorias[1] / completas])
		print("Empates (turno %d): %d (%.1f%%)" % [Rules.TURNO_EMPATE, empates, 100.0 * empates / completas])
		print("Turnos: média %.1f | mín %d | máx %d" % [float(total_turnos) / completas, turnos_min, turnos_max])
	if partidas_decididas > 0:
		print("Quem começa vence: %.1f%% (alvo 45–55%%)" % (100.0 * vitorias_de_quem_comeca / partidas_decididas))
	print("===========================================================")
	quit(1 if travadas > 0 else 0)
