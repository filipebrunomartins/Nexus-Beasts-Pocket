extends Node
## Autoload "Ctx" — contexto volátil passado entre telas (não persiste).

var deck_em_edicao := -1
var mapa_atual := 0

## Configuração da próxima batalha (preenchida pela campanha).
## {campanha, desafiante_id, mapa_idx, deck_ia, tipos_ia, nivel_ia,
##  nome_oponente, regras: [], fase_dupla}
var batalha: Dictionary = {}

## Resultado da última batalha de campanha, lido pela trilha ao voltar.
## {venceu, turnos, selos_oponente}
var resultado: Dictionary = {}
