extends Node
## Estado da partida atual (autoload "GameState").
## Guarda numeros que varios sistemas precisam ler (tempo, abates, nivel, XP,
## posicao do jogador) sem precisarem de referencia uns aos outros.

var is_running: bool = false
var elapsed: float = 0.0
var kills: int = 0
var level: int = 1
var xp: int = 0

## Atualizado pelo jogador a cada frame; lido por inimigos, gemas e spawner.
var player_position: Vector2 = Vector2.ZERO
var pickup_radius: float = 100.0


func reset() -> void:
	is_running = false
	elapsed = 0.0
	kills = 0
	level = 1
	xp = 0
	player_position = Vector2.ZERO
