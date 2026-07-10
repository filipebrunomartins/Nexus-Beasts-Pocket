extends Control
## Galeria de inspeção visual das cartas (dev only).
## NBP_DESDE=N mostra 4 cartas a partir do índice N (ordem por id).


func _ready() -> void:
	var db := CardDB.load_default()
	var desde := int(OS.get_environment("NBP_DESDE")) if OS.get_environment("NBP_DESDE") != "" else 0
	var bg := ColorRect.new()
	bg.color = Color("101020")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var grade := GridContainer.new()
	grade.columns = 2
	grade.add_theme_constant_override("h_separation", 12)
	grade.add_theme_constant_override("v_separation", 12)
	grade.set_anchors_preset(Control.PRESET_CENTER)
	grade.grow_horizontal = Control.GROW_DIRECTION_BOTH
	grade.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(grade)
	var cartas := db.all_cards()
	for i in range(desde, mini(desde + 4, cartas.size())):
		grade.add_child(CardRenderer.nova(db, cartas[i]["id"]))
