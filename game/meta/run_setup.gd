class_name RunSetup
extends RefCounted
## O que o jogador escolheu antes da partida: modo, personagem e mapa.
## Fica em GameState.setup e e lido pelo World ao comecar.

enum Mode { NORMAL, RANKED }

var mode: Mode = Mode.NORMAL
var character: CharacterData
var map: MapData


func is_ranked() -> bool:
	return mode == Mode.RANKED


## Duracao da partida em segundos; 0 = sem limite (ranqueado).
func duration() -> float:
	if is_ranked() or map == null:
		return 0.0
	return map.effective_duration()


func mode_name() -> String:
	return "Ranqueado" if is_ranked() else "Normal"
