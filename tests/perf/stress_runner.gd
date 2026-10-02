extends Node
## Teste de estresse (nao e teste GUT). Pula para o fim da partida, deixa o
## jogador invencivel e mede o custo da fisica por frame.
## Rodar: .\scripts\godot.ps1 --headless res://tests/perf/stress.tscn --fixed-fps 60

const WORLD_SCENE := preload("res://game/world/world.tscn")
const WARMUP_FRAMES := 600
const TOTAL_FRAMES := 1500
## Segundo da partida para onde pulamos (ondas mais pesadas).
const START_TIME := 545.0

var _world: World
var _frames: int = 0
var _samples: Array[float] = []
var _counts: Array[int] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_world = WORLD_SCENE.instantiate() as World
	_world.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(_world)


func _physics_process(_delta: float) -> void:
	_frames += 1
	if _frames == 2:
		GameState.elapsed = START_TIME
		var p := _world.get_node("Player") as Player
		p.health = Health.new(1e9)
		p.add_weapon(load("res://data/weapons/aura.tres") as WeaponData)
	get_tree().paused = false  # Ignora telas de level-up.
	if _frames > WARMUP_FRAMES and _frames % 2 == 0:
		_samples.append(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0)
		_counts.append(EnemyManager.find(get_tree()).count())
	if _frames == TOTAL_FRAMES:
		_report()
		get_tree().quit()


func _report() -> void:
	_samples.sort()
	var avg := 0.0
	for s: float in _samples:
		avg += s
	avg /= _samples.size()
	print("STRESS inimigos vivos (min/max): %d / %d" % [_counts.min(), _counts.max()])
	print("STRESS fisica por frame: media %.2f ms | p95 %.2f ms" % [
		avg, _samples[int(_samples.size() * 0.95)]])
	print("STRESS nos na arvore: %d" % Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
