class_name MatchRunner
extends RefCounted
## Utilitários de fluxo de partida compartilhados por simulador, testes e UI.


## Qual lado deve agir agora (setup e promoção não seguem jogador_atual).
static func lado_agindo(state: Dictionary) -> int:
	match state["fase"]:
		"promocao":
			return state["promocoes_pendentes"][0]
		"setup":
			return 0 if state["jogadores"][0]["ativo"] == null else 1
		_:
			return state["jogador_atual"]
