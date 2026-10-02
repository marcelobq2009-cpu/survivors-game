class_name World
extends Node2D
## Cena da partida. Comeca/termina a partida e conta o tempo.
## Os sistemas filhos (jogador, inimigos, armas, UI) conversam via Events.

@export var timeline: WaveTimeline


func _ready() -> void:
	get_tree().paused = false
	Pool.clear()
	GameState.reset()
	GameState.is_running = true
	Events.player_died.connect(_end_run.bind(false))
	Events.run_started.emit()
	Events.xp_changed.emit(0, GameState.progression.xp_needed(), 1)


func _exit_tree() -> void:
	GameState.is_running = false
	Pool.clear()


func _physics_process(delta: float) -> void:
	if not GameState.is_running:
		return
	GameState.elapsed += delta
	if timeline and GameState.elapsed >= timeline.run_duration:
		_end_run(true)


func _end_run(victory: bool) -> void:
	if not GameState.is_running:
		return
	GameState.is_running = false
	Save.submit_run(GameState.elapsed, GameState.kills)
	get_tree().paused = true
	Events.run_ended.emit(victory)
