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
var _next_event: float = 0.0
## Areas contaminadas ativas: [posicao, raio, segundos restantes, aviso restante, timer de dano]
var _toxic: Array[Array] = []
const TOXIC_RADIUS := 3.6
const TOXIC_DURATION := 10.0
const TOXIC_WARNING := 1.5
const TOXIC_DAMAGE := 5.0
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
	_next_event = profile.event_interval * 0.6 if profile and profile.event_interval > 0.0 else INF


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
	# Eventos especiais.
	if t >= _next_event:
		_next_event += director.profile.event_interval * _rng.randf_range(0.85, 1.15)
		if t >= director.profile.toxic_from and _rng.randf() < 0.5:
			spawn_toxic_zone()
		else:
			spawn_supply_drop()
	_update_toxic(delta)
	# Spawn continuo.
	_timer -= delta
	if _timer > 0.0:
		return
	_timer = wave.spawn_interval / (director.spawn_rate_mult(t) * Config.game.enemy_spawn_multiplier)
	var cap := mini(roundi(Config.game.max_active_enemies * Save.profile.settings.enemy_density),
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
	_boss_camera()


## Afasta a camera para mostrar o chefe e volta depois (coroutine: se a partida
## acabar no meio, ela simplesmente para).
func _boss_camera() -> void:
	var rig := CameraRig.find(get_tree())
	if rig == null:
		return
	rig.zoom_to(rig.default_zoom * 1.3, 0.8)
	await get_tree().create_timer(3.0, false).timeout
	if is_instance_valid(rig):
		rig.zoom_to(0.0, 1.0)


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
		Events.event_started.emit(&"horde", GameState.player_position)


func _spawn(data: EnemyData, pos: Vector2, wave_hp: float, elite: bool) -> void:
	var t := GameState.elapsed
	manager.spawn(data, pos, wave_hp * director.health_mult(t), director.damage_mult(t),
			director.speed_mult(t), elite, director.profile)


## Queda de suprimentos: caixa cai perto do jogador (vira um bau ao pousar).
func spawn_supply_drop() -> void:
	var map := GameMap.find(get_tree())
	if map == null:
		return
	var pos := map.random_free_point_around(GameState.player_position, _rng.randf_range(11.0, 17.0), _rng, 16)
	if pos == Vector2.INF:
		return
	Events.event_started.emit(&"supply", pos)
	Events.announcement.emit("SUPRIMENTOS CAINDO! VÁ ATÉ A CAIXA", Color(0.55, 1, 0.5))
	var fx := Effects.find(get_tree())
	if fx:
		fx.supply_beacon(pos, 2.0)
	await get_tree().create_timer(2.0, false).timeout
	var pickups := PickupManager.find(get_tree())
	if pickups and GameState.is_running:
		pickups.spawn(PickupManager.Kind.CHEST, pos, 40)


## Area contaminada: aviso no chao e depois dano em quem ficar dentro.
func spawn_toxic_zone() -> void:
	var map := GameMap.find(get_tree())
	var pos := GameState.player_position + Vector2.from_angle(_rng.randf() * TAU) * _rng.randf_range(2.0, 6.0)
	if map:
		pos = map.grid.nearest_free(pos)
	_toxic.append([pos, TOXIC_RADIUS, TOXIC_DURATION, TOXIC_WARNING, 0.0])
	Events.event_started.emit(&"toxic", pos)
	Events.announcement.emit("ÁREA CONTAMINADA! SAIA DO VERDE", Color(0.6, 1, 0.3))
	var fx := Effects.find(get_tree())
	if fx:
		fx.toxic_zone(pos, TOXIC_RADIUS, TOXIC_WARNING, TOXIC_DURATION)


func _update_toxic(delta: float) -> void:
	for i: int in range(_toxic.size() - 1, -1, -1):
		var z: Array = _toxic[i]
		z[2] = float(z[2]) - delta
		z[3] = float(z[3]) - delta
		z[4] = float(z[4]) - delta
		if float(z[2]) <= 0.0:
			_toxic.remove_at(i)
			continue
		if float(z[3]) > 0.0 or float(z[4]) > 0.0:
			continue  # ainda no aviso (ou esperando o proximo tick)
		z[4] = 0.5
		var pos: Vector2 = z[0]
		if pos.distance_to(GameState.player_position) <= float(z[1]) + GameState.player_radius:
			Events.player_contact.emit(TOXIC_DAMAGE * director.damage_mult(GameState.elapsed),
					"Área contaminada")


## Areas perigosas ativas (para indicadores): Array de [posicao, raio].
func toxic_zones() -> Array[Array]:
	var out: Array[Array] = []
	for z: Array in _toxic:
		out.append([z[0], z[1]])
	return out
