extends Node
## Autoload "Ctx" — contexto volátil passado entre telas (não persiste).

var deck_em_edicao := -1

## Configuração da próxima batalha (preenchida pela campanha).
## {deck_ia, tipos_ia, nivel_ia, nome_oponente, desafiante_id, regras_chefe}
var batalha: Dictionary = {}
