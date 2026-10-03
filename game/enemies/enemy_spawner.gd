class_name EnemySpawner
extends Node
## Cria zumbis seguindo a WaveTimeline do mapa (QUAIS zumbis) e o
## DifficultyDirector (QUANTO/QUAO FORTES). Tambem agenda chefes e hordas.
## Posicoes: logo fora da tela, em celula livre do mapa (nada dentro de
## predios, nada fora das bordas), a uma distancia minima do jogador.

const GROUP := &"enemy_spawner"
const SPAWN_MARGIN := 3.0
const ATTEMPTS := 10

var timeline: WaveTimeline
var director: DifficultyDirector
var manager: EnemyManager

var _timer: float = 0.0
var _bosses_spawned: int = 0
var _next_horde: float = 0.0
var _rng := RandomNumberGenerator.new()


func _enter_tree() -> void:
	add_to_group(GROUP)


static func find(tree: SceneTree) -> EnemySpawner:
	return tree.get_first_node_in_group(GROUP) as EnemySpawner


func setup(p_timeline: WaveTimeline, profile: DifficultyProfile, p_manager: EnemyManager) -> void:
	timeline = p_timeline
	manager = p_manager
	director = DifficultyDirector.new(profile, timeline.run_duration if timeline else 600.0)
	_rng.randomize()
	_next_horde = profile.horde_interval if profile and profile.horde_interval > 0.0 else INF


func _physics_process(delta: float) -> void:
	if not GameState.is_running or timeline == null or manager == null:
		return
	var t := GameState.elapsed
	var wave := timeline.get_wave_at(t)
	if wave == null or wave.enemies.is_empty():
		return
	# Chefes agendados.
	var due := director.boss_index(t)
	while _bosses_spawned <= due:
		spawn_boss(_bosses_spawned)
		_bosses_spawned += 1
	# Hordas (cerco em volta do jogador).
	if t >= _next_horde:
		_next_horde += director.profile.horde_interval
		spawn_horde(director.horde_size(t))
	# Spawn continuo.
	_timer -= delta
	if _timer > 0.0:
		return
	_timer = wave.spawn_interval / (director.spawn_rate_mult(t) * Config.game.enemy_spawn_multiplier)
	var cap := mini(Config.game.max_active_enemies,
			roundi(wave.max_alive * minf(2.0, director.spawn_rate_mult(t))))
	for i: int in wave.spawn_count:
		if manager.count() >= cap:
			break
		var data: EnemyData = wave.enemies[_rng.randi_range(0, wave.enemies.size() - 1)]
		var pos := offscreen_point()
		if pos != Vector2.INF:
			_spawn(data, pos, wave.health_multiplier, _rng.randf() < director.elite_chance(t))


## Ponto livre logo fora da tela (ou Vector2.INF se nao achou).
func offscreen_point(extra: float = 0.0) -> Vector2:
	var map := GameMap.find(get_tree())
	var rig := CameraRig.find(get_tree())
	var r := (rig.visible_ground_radius() if rig else 25.0) + SPAWN_MARGIN + extra
	if map == null:
		return GameState.player_position + Vector2.from_angle(_rng.randf() * TAU) * r
	return map.random_free_point_around(GameState.player_position, r + _rng.randf_range(0, 3), _rng, ATTEMPTS)


func spawn_boss(index: int) -> void:
	var bosses := director.profile.bosses
	if bosses.is_empty():
		return
	var data: EnemyData = bosses[index % bosses.size()]
	var pos := offscreen_point(-4.0)
	if pos == Vector2.INF:
		pos = GameState.player_position + Vector2(0, -12)
	var t := GameState.elapsed
	manager.spawn(data, pos, director.boss_health_mult(index, t), director.damage_mult(t), 1.0)
	Events.boss_spawned.emit(data)
	Events.announcement.emit("UM CHEFE APARECEU: %s" % data.display_name.to_upper(), Color(1, 0.35, 0.3))
	Audio.play(&"boss")
	var rig := CameraRig.find(get_tree())
	if rig:
		rig.zoom_to(rig.default_zoom * 1.3, 0.8)
		get_tree().create_timer(3.0, false).timeout.connect(func() -> void: rig.zoom_to(0.0, 1.0))


## Cerco: N zumbis em anel em volta do jogador, ao mesmo tempo.
func spawn_horde(size: int) -> void:
	var wave := timeline.get_wave_at(GameState.elapsed)
	if wave == null or wave.enemies.is_empty():
		return
	var map := GameMap.find(get_tree())
	var rig := CameraRig.find(get_tree())
	var r := (rig.visible_ground_radius() if rig else 25.0) * 0.85
	var room := Config.game.max_active_enemies - manager.count()
	var n := mini(size, room)
	for i: int in n:
		var p := GameState.player_position + Vector2.from_angle(TAU * i / maxf(1, n)) * r
		if map and map.grid.is_blocked(p):
			continue
		_spawn(wave.enemies[i % wave.enemies.size()], p, wave.health_multiplier, false)
	if n > 0:
		Events.announcement.emit("HORDA SE APROXIMANDO!", Color(1, 0.75, 0.3))
		Audio.play(&"horde")


func _spawn(data: EnemyData, pos: Vector2, wave_hp: float, elite: bool) -> void:
	var t := GameState.elapsed
	manager.spawn(data, pos, wave_hp * director.health_mult(t), director.damage_mult(t),
			director.speed_mult(t), elite, director.profile)
