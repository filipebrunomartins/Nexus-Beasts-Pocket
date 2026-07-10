extends SceneTree
## Validador do cards.json — roda com:
##   godot --headless -s tools/validate_cards.gd
## Confere contagens do set, integridade de evoluções, tipos/custos válidos
## e campos obrigatórios por categoria. Sai com código 1 se houver erro.

const VALID_CATEGORIES := ["besta", "mentor", "item", "ferramenta", "reliquia"]
const VALID_STATUS := ["envenenado", "queimado", "adormecido", "paralisado", "confuso"]

var errors: PackedStringArray = []


func _init() -> void:
	var db := CardDB.load_default()
	_validate(db)
	if errors.is_empty():
		print("✔ cards.json válido: %d cartas no set \"%s\"" % [db.cards.size(), db.set_name])
		quit(0)
	else:
		for e in errors:
			printerr("✘ " + e)
		printerr("%d erro(s) de validação." % errors.size())
		quit(1)


func _validate(db: CardDB) -> void:
	var by_type: Dictionary = {}
	var omega_by_type: Dictionary = {}
	var names: Dictionary = {}
	var monsters := 0
	var allies := 0

	for card: Dictionary in db.all_cards():
		var id: String = card["id"]
		if not card["nome"] in names:
			names[card["nome"]] = id
		else:
			errors.append("%s: nome duplicado com %s" % [id, names[card["nome"]]])
		if not VALID_CATEGORIES.has(card["categoria"]):
			errors.append("%s: categoria inválida '%s'" % [id, card["categoria"]])
			continue

		if card["categoria"] == "besta":
			monsters += 1
			_validate_beast(db, card, by_type, omega_by_type)
		else:
			allies += 1
			_validate_ally(db, card)

	if monsters != 60:
		errors.append("Esperados 60 monstros, encontrados %d" % monsters)
	if allies != 19:
		errors.append("Esperados 19 aliados, encontrados %d" % allies)
	for tipo in db.types.keys():
		if int(by_type.get(tipo, 0)) != 6:
			errors.append("Tipo %s: esperados 6 monstros, encontrados %d" % [tipo, by_type.get(tipo, 0)])
		if int(omega_by_type.get(tipo, 0)) != 1:
			errors.append("Tipo %s: esperado 1 Ω, encontrados %d" % [tipo, omega_by_type.get(tipo, 0)])


func _validate_beast(db: CardDB, card: Dictionary, by_type: Dictionary, omega_by_type: Dictionary) -> void:
	var id: String = card["id"]
	var tipo: String = card.get("tipo", "")
	if not db.types.has(tipo):
		errors.append("%s: tipo inválido '%s'" % [id, tipo])
		return
	by_type[tipo] = int(by_type.get(tipo, 0)) + 1
	if card.get("omega", false):
		omega_by_type[tipo] = int(omega_by_type.get(tipo, 0)) + 1

	if int(card.get("ps", 0)) <= 0 or int(card["ps"]) % 10 != 0:
		errors.append("%s: PS inválido (%s)" % [id, card.get("ps")])
	var recuo := int(card.get("recuo", -1))
	if recuo < 0 or recuo > 4:
		errors.append("%s: recuo inválido (%d)" % [id, recuo])

	var fraqueza: Variant = card.get("fraqueza")
	if fraqueza != null and not db.types.has(fraqueza):
		errors.append("%s: fraqueza inválida '%s'" % [id, fraqueza])
	if tipo == "mito" and fraqueza != null:
		errors.append("%s: Mito não deve ter fraqueza" % id)

	var estagio := int(card.get("estagio", -1))
	var evolui: Variant = card.get("evolui_de")
	if estagio == 0 and evolui != null:
		errors.append("%s: básico não deve ter evolui_de" % id)
	if estagio > 0:
		if evolui == null or not db.has_card(evolui):
			errors.append("%s: evolui_de inválido '%s'" % [id, evolui])
		else:
			var pre: Dictionary = db.get_card(evolui)
			if int(pre.get("estagio", -1)) != estagio - 1:
				errors.append("%s: evolui de %s mas estágios não batem" % [id, evolui])
			if pre.get("tipo") != tipo:
				errors.append("%s: evolui de %s mas tipos diferem" % [id, evolui])

	var ataques: Array = card.get("ataques", [])
	if ataques.is_empty():
		errors.append("%s: besta sem ataques" % id)
	for atk: Dictionary in ataques:
		for custo: String in atk.get("custo", []):
			if custo != "qualquer" and (not db.types.has(custo) or not db.get_type(custo).get("tem_energia", false)):
				errors.append("%s: custo de energia inválido '%s' em %s" % [id, custo, atk.get("nome")])
		if int(atk.get("dano", -1)) < 0:
			errors.append("%s: dano inválido em %s" % [id, atk.get("nome")])
		_validate_effects(id, atk.get("efeitos", []))
	if card.get("habilidade") != null:
		_validate_effects(id, card["habilidade"].get("efeitos", []))


func _validate_ally(db: CardDB, card: Dictionary) -> void:
	var id: String = card["id"]
	if String(card.get("texto", "")).is_empty():
		errors.append("%s: aliado sem texto" % id)
	if card["categoria"] == "reliquia":
		var rel: Dictionary = card.get("reliquia", {})
		if int(rel.get("ps", 0)) <= 0 or not db.types.has(rel.get("tipo", "")):
			errors.append("%s: bloco 'reliquia' inválido" % id)
	elif card.get("efeitos", []).is_empty():
		errors.append("%s: aliado sem efeitos" % id)
	_validate_effects(id, card.get("efeitos", []))


func _validate_effects(id: String, effects: Array) -> void:
	for ef: Dictionary in effects:
		if not ef.has("bloco"):
			errors.append("%s: efeito sem 'bloco'" % id)
			continue
		if ef["bloco"] == "status" and not VALID_STATUS.has(ef.get("status", "")):
			errors.append("%s: status inválido '%s'" % [id, ef.get("status")])
		if ef["bloco"] == "moeda":
			_validate_effects(id, ef.get("se_cara", []))
			_validate_effects(id, ef.get("se_coroa", []))
