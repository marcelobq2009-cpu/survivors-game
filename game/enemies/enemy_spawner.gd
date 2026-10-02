class_name EnemySpawner
extends Node
## Cria inimigos fora da tela seguindo a WaveTimeline (data/waves/).

@export var timeline: WaveTimeline
@export var manager: EnemyManager

var _timer: float = 0.0
var _rng := RandomNumberGenerator.new()


func _physics_process(delta: float) -> void:
	if not GameState.is_running or timeline == null:
		return
	var wave := timeline.get_wave_at(GameState.elapsed)
	if wave == null or wave.enemies.is_empty():
		return
	_timer -= delta
	if _timer > 0.0:
		return
	_timer = wave.spawn_interval
	for i: int in wave.spawn_count:
		if manager.count() >= wave.max_alive:
			break
		var data: EnemyData = wave.enemies[_rng.randi_range(0, wave.enemies.size() - 1)]
		var pos := GameState.player_position + ring_offset(manager.get_viewport(), _rng)
		manager.spawn(data, pos, wave.health_multiplier)


## Distancia do centro da tela ate um ponto garantidamente fora dela.
static func offscreen_radius(viewport: Viewport) -> float:
	var size := viewport.get_visible_rect().size
	var cam := viewport.get_camera_2d()
	if cam:
		size /= cam.zoom
	return size.length() * 0.5 + 60.0


## Deslocamento aleatorio num anel logo fora da tela.
static func ring_offset(viewport: Viewport, rng: RandomNumberGenerator = null) -> Vector2:
	var angle := rng.randf() * TAU if rng else randf() * TAU
	var r := offscreen_radius(viewport)
	return Vector2.from_angle(angle) * r
