class_name WaveTimeline
extends Resource
## Lista de ondas da partida, em ordem de start_time.

## Duracao da partida em segundos (ao chegar aqui, o jogador vence).
@export var run_duration: float = 600.0
@export var waves: Array[WaveData] = []


## Retorna a onda ativa no tempo `t` (a ultima cujo start_time <= t).
func get_wave_at(t: float) -> WaveData:
	var current: WaveData = null
	for wave: WaveData in waves:
		if wave.start_time <= t and (current == null or wave.start_time >= current.start_time):
			current = wave
	return current
