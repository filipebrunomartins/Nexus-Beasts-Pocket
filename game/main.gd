extends Control
## Cena raiz do jogo. Nas primeiras etapas serve como tela de boot;
## a partir da Etapa 8 passa a rotear para a Home.


func _ready() -> void:
	print("Nexus Beasts Pocket — boot OK (Godot %s)" % Engine.get_version_info()["string"])
