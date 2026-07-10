extends Node
## Autoload "Save" — perfil do jogador persistido em user://save.json.
## Tudo que sobrevive entre sessões mora aqui (coleção, decks, timers,
## campanha, missões, economia).

const ARQUIVO := "user://save.json"
const VERSAO := 1

var dados: Dictionary = {}


func _ready() -> void:
	carregar()


func carregar() -> void:
	if FileAccess.file_exists(ARQUIVO):
		var file := FileAccess.open(ARQUIVO, FileAccess.READ)
		var parsed: Variant = JSON.parse_string(file.get_as_text())
		if parsed is Dictionary and int(parsed.get("versao", 0)) >= 1:
			dados = parsed
			_migrar()
			return
	dados = _novo_perfil()
	salvar()


func salvar() -> void:
	var file := FileAccess.open(ARQUIVO, FileAccess.WRITE)
	file.store_string(JSON.stringify(dados, "\t"))


func resetar() -> void:
	dados = _novo_perfil()
	salvar()


func _novo_perfil() -> Dictionary:
	# O novato começa com os 2 decks emprestados da Parte 5 (e suas cartas)
	# e 1 pacote liberado na hora.
	var colecao := {}
	var decks := []
	for deck in CardDB.load_decks():
		var cartas_deck: Array = deck["cartas"]
		for id in cartas_deck:
			colecao[id] = maxi(int(colecao.get(id, 0)), cartas_deck.count(id))
		decks.append({"nome": deck["nome"], "cartas": cartas_deck.duplicate(), "emprestado": true})
	return {
		"versao": VERSAO,
		"moedas": 0,
		"ampulhetas": 3,
		"xp": 0,
		"colecao": colecao,
		"decks": decks,
		"deck_ativo": 0,
		"prox_pacote_ts": 0,
		"pacotes_abertos": 0,
		"pacotes_bonus": 0,
		"campanha": {"vencidos": {}, "estrelas": {}},
		"missoes": {"dia": "", "lista": []},
		"titulos": [],
		"tutorial_feito": false,
	}


func _migrar() -> void:
	# Espaço para migrações de versões futuras do save.
	pass

# ------------------------------------------------ coleção

func qtd_na_colecao(card_id: String) -> int:
	return int(dados["colecao"].get(card_id, 0))


func adicionar_cartas(ids: Array) -> void:
	for id in ids:
		dados["colecao"][id] = qtd_na_colecao(id) + 1
	salvar()


func total_cartas_unicas() -> int:
	return (dados["colecao"] as Dictionary).size()
