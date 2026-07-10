extends NBTest
## Testes do sistema de pacotes e da estrutura do save.


func _perfil() -> Dictionary:
	# réplica do perfil novo (sem depender do autoload em testes headless)
	return {
		"moedas": 0, "ampulhetas": 3, "colecao": {},
		"prox_pacote_ts": 0, "pacotes_abertos": 0,
	}


func test_timer_de_12h() -> void:
	var perfil := _perfil()
	ok(PackSystem.pode_abrir(perfil, 1000), "pacote inicial liberado")
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	PackSystem.abrir(db, perfil, 1000, rng)
	ok(not PackSystem.pode_abrir(perfil, 1000), "trava após abrir")
	igual(PackSystem.segundos_restantes(perfil, 1000), PackSystem.INTERVALO_SEG, "12h de espera")
	ok(PackSystem.pode_abrir(perfil, 1000 + PackSystem.INTERVALO_SEG), "libera após 12h")


func test_ampulheta_reduz_1h() -> void:
	var perfil := _perfil()
	var rng := RandomNumberGenerator.new()
	rng.seed = 2
	PackSystem.abrir(db, perfil, 0, rng)
	ok(PackSystem.usar_ampulheta(perfil), "ampulheta usada")
	igual(perfil["ampulhetas"], 2, "estoque decrementado")
	igual(PackSystem.segundos_restantes(perfil, 0), PackSystem.INTERVALO_SEG - 3600, "1h a menos")
	perfil["ampulhetas"] = 0
	ok(not PackSystem.usar_ampulheta(perfil), "sem estoque, falha")


func test_pacote_tem_5_cartas_validas() -> void:
	var perfil := _perfil()
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var cartas := PackSystem.abrir(db, perfil, 0, rng)
	igual(cartas.size(), 5, "5 cartas por pacote")
	for id in cartas:
		ok(db.has_card(id), "carta válida: %s" % id)


func test_distribuicao_de_raridade() -> void:
	# 400 pacotes: slots 1–2 sempre ♦1; slot 5 nunca ♦1; Ω (♦4) aparece só no slot 5.
	var rng := RandomNumberGenerator.new()
	rng.seed = 4
	var omegas := 0
	for i in 400:
		var perfil := _perfil()
		var cartas := PackSystem.abrir(db, perfil, 0, rng)
		for slot in 2:
			igual(int(db.get_card(cartas[slot]).get("raridade", 1)), 1, "slots iniciais são ♦1")
		var r5 := int(db.get_card(cartas[4]).get("raridade", 1))
		ok(r5 >= 2, "slot 5 nunca é comum")
		for slot in 4:
			ok(int(db.get_card(cartas[slot]).get("raridade", 1)) < 4, "Ω só no slot 5")
		if r5 == 4:
			omegas += 1
	ok(omegas > 20 and omegas < 140, "taxa de Ω plausível (%d/400 ≈ 18%%)" % omegas)


func test_tabela_probabilidades_texto() -> void:
	var texto := PackSystem.tabela_probabilidades()
	ok(texto.contains("Carta 5"), "tabela cobre os 5 slots")
	ok(texto.contains("♦4"), "menciona a raridade Ω")
