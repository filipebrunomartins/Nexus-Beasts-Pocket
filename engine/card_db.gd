class_name CardDB
extends RefCounted
## Banco de cartas: carrega e indexa data/cards/*.json.
## Biblioteca pura — sem Nodes, utilizável em testes headless e (V2) no servidor.

const CARDS_PATH := "res://data/cards/cards.json"
const TYPES_PATH := "res://data/cards/types.json"

var cards: Dictionary = {}        # id -> Dictionary da carta
var types: Dictionary = {}        # id do tipo -> Dictionary do tipo
var set_id: String = ""
var set_name: String = ""


static func load_default() -> CardDB:
	var db := CardDB.new()
	db.load_from_files(CARDS_PATH, TYPES_PATH)
	return db


func load_from_files(cards_path: String, types_path: String) -> void:
	var cards_data: Dictionary = _read_json(cards_path)
	var types_data: Dictionary = _read_json(types_path)
	set_id = cards_data.get("set", "")
	set_name = cards_data.get("nome_set", "")
	for card: Dictionary in cards_data.get("cartas", []):
		cards[card["id"]] = card
	for tipo: Dictionary in types_data.get("tipos", []):
		types[tipo["id"]] = tipo


func get_card(id: String) -> Dictionary:
	assert(cards.has(id), "Carta inexistente: %s" % id)
	return cards[id]


func has_card(id: String) -> bool:
	return cards.has(id)


func get_type(id: String) -> Dictionary:
	assert(types.has(id), "Tipo inexistente: %s" % id)
	return types[id]


func all_cards() -> Array:
	var list := cards.values()
	list.sort_custom(func(a, b): return a["id"] < b["id"])
	return list


## Categorias que entram em jogo como monstro (bestas e relíquias).
static func is_playable_as_beast(card: Dictionary) -> bool:
	return card["categoria"] == "besta" or card["categoria"] == "reliquia"


static func is_basic_beast(card: Dictionary) -> bool:
	return card["categoria"] == "besta" and int(card.get("estagio", -1)) == 0


const DECKS_PATH := "res://data/cards/decks.json"


## Decks pré-montados (Parte 5): [{id, nome, tipos_mana, cartas}, ...]
static func load_decks() -> Array:
	return _read_json(DECKS_PATH).get("decks", [])


static func _read_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	assert(file != null, "Não foi possível abrir %s" % path)
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	assert(parsed is Dictionary, "JSON inválido em %s" % path)
	return parsed
