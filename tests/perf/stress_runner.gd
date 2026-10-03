extends Node
## Teste de estresse (nao e teste GUT). Pula para o minuto 25, deixa o jogador
## invencivel, da armas extras e mede o custo por frame com a horda no maximo.
## Rodar: scripts/godot.(ps1|sh) --headless res://tests/perf/stress.tscn --fixed-fps 60

const WORLD_SCENE := preload("res://game/world/world.tscn")
const WARMUP_FRAMES := 900
const TOTAL_FRAMES := 2100
const START_TIME := 1500.0

var _world: World
var _frames: int = 0
var _physics: Array[float] = []
var _process: Array[float] = []
var _counts: Array[int] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Save.set_storage_path("user://stress_save.json")
	Save.profile.tutorial_done = true
	GameState.setup = RunSetup.new()
	GameState.setup.map = Content.find_map(&"rio")
	GameState.setup.character = Content.find_character(&"survivor")
	_world = WORLD_SCENE.instantiate() as World
	_world.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(_world)


func _physics_process(_delta: float) -> void:
	_frames += 1
	if _frames == 3:
		GameState.elapsed = START_TIME
		var p := Player.find(get_tree())
		p.health.god_mode = true
		for id: String in ["shotgun", "gas", "molotov", "machete"]:
			p.add_weapon(load("res://data/weapons/%s.tres" % id) as WeaponData)
	GameState.clear_pauses()
	get_tree().paused = false  # Ignora telas de level-up.
	if _frames > WARMUP_FRAMES and _frames % 2 == 0:
		_physics.append(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0)
		_process.append(Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0)
		_counts.append(EnemyManager.find(get_tree()).count())
	if _frames == TOTAL_FRAMES:
		_report()
		Save.set_storage_path(Save.DEFAULT_PATH)
		get_tree().quit()


func _report() -> void:
	print("STRESS zumbis vivos (min/max): %d / %d" % [_counts.min(), _counts.max()])
	print("STRESS fisica por frame: %s" % _stats(_physics))
	print("STRESS process (render em lote) por frame: %s" % _stats(_process))
	print("STRESS projeteis: %d | gemas: %d | nos: %d" % [
		ProjectileManager.find(get_tree()).count(), PickupManager.find(get_tree()).gem_count(),
		Performance.get_monitor(Performance.OBJECT_NODE_COUNT)])


func _stats(values: Array[float]) -> String:
	values.sort()
	var avg := 0.0
	for v: float in values:
		avg += v
	avg /= maxf(1.0, values.size())
	return "media %.2f ms | p95 %.2f ms" % [avg, values[int(values.size() * 0.95)]]
