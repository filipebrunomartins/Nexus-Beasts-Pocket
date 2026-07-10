extends SceneTree
## Executor de testes headless:
##   godot --headless -s tests/run_all.gd
## Roda todos os métodos test_* dos scripts listados e sai com 1 se algo falhar.

const TEST_SCRIPTS := [
	"res://tests/test_rules.gd",
	"res://tests/test_effects.gd",
	"res://tests/test_packs.gd",
]


func _init() -> void:
	var total := 0
	var falhas_totais: PackedStringArray = []
	for path in TEST_SCRIPTS:
		if not ResourceLoader.exists(path):
			continue
		var inst: NBTest = load(path).new()
		for m in inst.get_method_list():
			if not m["name"].begins_with("test_"):
				continue
			inst.antes()
			inst.call(m["name"])
			total += 1
			for f in inst.falhas:
				falhas_totais.append("%s::%s — %s" % [path.get_file(), m["name"], f])
			inst.falhas.clear()

	if falhas_totais.is_empty():
		print("✔ %d testes passaram." % total)
		quit(0)
	else:
		for f in falhas_totais:
			printerr("✘ " + f)
		printerr("%d falha(s) em %d testes." % [falhas_totais.size(), total])
		quit(1)
