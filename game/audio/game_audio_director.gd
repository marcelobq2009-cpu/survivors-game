class_name GameAudioDirector
extends Node3D
## "Diretor de audio" da partida: escuta os Events e decide o que tocar.
## - Musica: constroi tensao (camadas), troca para a trilha do chefe e volta.
## - Zumbis: vozes por tipo vindas da posicao deles (limitadas), murmurio da horda.
## - Ambiente: cidade / orla / morro + sons ocasionais e assinaturas (Cristo, bondinho).
## - Feedback: impactos, criticos, mortes, XP (tom sobe em sequencia), ouro,
##   vida baixa (coracao), cura, elites, explosoes e eventos.
## Tambem informa ao Audio onde esta o "ouvido" (jogador) e para que lado a
## camera olha: som da esquerda da tela sai na esquerda do fone.

const VOICE_INTERVAL := 0.32
const VOICE_RADIUS := 15.0
const LOW_HP := 0.3

var _voice_timer: float = 0.0
var _env_timer: float = 0.0
var _oneshot_timer: float = 6.0
var _xp_combo: int = 0
var _xp_combo_timer: float = 0.0
var _hp_ratio: float = 1.0
var _boss_active: bool = false
var _boss_phase2: bool = false
var _music_before_boss: StringName = &""
var _seen_runners: Dictionary = {}
var _elite_alert_cooldown: float = 0.0
var _rng := RandomNumberGenerator.new()
var _nearby: Array[EnemyAgent] = []


func _ready() -> void:
	_rng.randomize()
	Events.run_started.connect(_on_run_started)
	Events.run_ended.connect(_on_run_ended)
	Events.damage_dealt.connect(_on_damage)
	Events.enemy_killed.connect(_on_killed)
	Events.explosion.connect(func(pos: Vector2, _r: float, sound: StringName) -> void:
		Audio.play_at(sound, pos))
	Events.explosion_warning.connect(func(pos: Vector2, _r: float, _d: float) -> void:
		Audio.play_at(&"zombie_bloater_fuse", pos))
	Events.charge_warning.connect(func(pos: Vector2, _dir: Vector2, _l: float, _d: float) -> void:
		Audio.play_at(&"boss_charge", pos))
	Events.elite_spawned.connect(_on_elite)
	Events.boss_spawned.connect(_on_boss_spawned)
	Events.boss_killed.connect(_on_boss_killed)
	Events.xp_collected.connect(_on_xp)
	Events.gold_collected.connect(func(_g: int) -> void: Audio.play(&"pickup_gold"))
	Events.chest_opened.connect(func() -> void: Audio.play(&"reward_chest"))
	Events.level_up.connect(func(_l: int) -> void:
		Audio.play(&"level_up")
		Audio.duck(SoundCatalog.BUS_SFX, -10.0, 0.8)
		Audio.duck(SoundCatalog.BUS_ZOMBIES, -12.0, 0.8))
	Events.player_damaged.connect(func(_a: float) -> void: Audio.play(&"player_hurt"))
	Events.player_healed.connect(func(_a: float) -> void: Audio.play(&"player_heal"))
	Events.player_health_changed.connect(_on_health)
	Events.event_started.connect(_on_event)
	Events.upgrade_chosen.connect(func(u: UpgradeData) -> void:
		if u.kind == UpgradeData.Kind.EVOLVE:
			Audio.duck(SoundCatalog.BUS_SFX, -14.0, 2.0)
			Audio.duck(SoundCatalog.BUS_ZOMBIES, -14.0, 2.0)
			Audio.play(&"weapon_evolve"))


func _exit_tree() -> void:
	Audio.stop_all_loops()
	Audio.set_ambience(&"")
	Audio.set_combat_music(false)


func _on_run_started() -> void:
	Audio.set_combat_music(true)
	Audio.set_intensity(1)


func _on_run_ended(result: RunResult) -> void:
	Audio.stop_all_loops()
	Audio.set_combat_music(false)
	Audio.set_ambience(&"")
	Audio.stop_music()
	Audio.stinger(&"victory" if result.victory else &"defeat", -40.0)


func _process(delta: float) -> void:
	var rig := CameraRig.find(get_tree())
	if rig and rig.camera:
		# Ouvido no jogador, virado como a camera (esquerda da tela = esquerda do fone).
		Audio.set_listener(GameState.player_position, rig.camera.global_basis.x)
	if not GameState.is_running:
		return
	_xp_combo_timer -= delta
	if _xp_combo_timer <= 0.0:
		_xp_combo = 0
	_elite_alert_cooldown -= delta
	_voice_timer -= delta
	if _voice_timer <= 0.0:
		_voice_timer = VOICE_INTERVAL
		_zombie_voices()
	_env_timer -= delta
	if _env_timer <= 0.0:
		_env_timer = 0.5
		_update_environment()
		_update_music()
	_oneshot_timer -= delta
	if _oneshot_timer <= 0.0:
		_oneshot_timer = _rng.randf_range(7.0, 15.0)
		_ambient_oneshot()


# --- Musica ------------------------------------------------------------------

func _update_music() -> void:
	var t := GameState.elapsed
	var m := EnemyManager.find(get_tree())
	var near := 0
	if m:
		m.grid.query_radius(GameState.player_position, VOICE_RADIUS, _nearby)
		near = _nearby.size()
	if _boss_active:
		var boss: EnemyAgent = m.current_boss() if m else null
		if boss and boss.hp_ratio() < 0.5 and not _boss_phase2:
			_boss_phase2 = true
			Events.announcement.emit("O CHEFE ESTÁ FURIOSO!", Color(1, 0.3, 0.25))
			Audio.play_at(&"boss_colossus_roar" if boss.data.id == &"boss_colossus" else &"boss_mutant_roar",
					boss.pos)
		Audio.set_intensity(2 if _boss_phase2 else 1)
		return
	if GameState.setup.is_ranked():
		# Ranqueado: pulso constante que cresce com o tempo sobrevivido.
		Audio.set_intensity(1 if t < 60.0 else (2 if t < 300.0 else 3))
		return
	# Normal: comeca calmo e constroi tensao (tempo + quantidade de zumbis perto).
	var dur := GameState.setup.duration()
	var level := 1
	if t > 75.0:
		level = 2
	if t > 360.0 or near > 45:
		level = 3
	if t > 900.0 or near > 110 or (dur > 0.0 and t > dur - 180.0):
		level = 4
	Audio.set_intensity(level)


func _on_boss_spawned(data: EnemyData) -> void:
	_boss_active = true
	_boss_phase2 = false
	_music_before_boss = Audio.current_music()
	Audio.stinger(&"boss_intro", -30.0)
	Audio.play_music(&"boss")
	var roar := &"boss_colossus_roar" if data.id == &"boss_colossus" else &"boss_mutant_roar"
	await get_tree().create_timer(0.6, false).timeout
	var m := EnemyManager.find(get_tree())
	var b: EnemyAgent = m.current_boss() if m else null
	Audio.play_at(roar, b.pos if b else GameState.player_position)


func _on_boss_killed(data: EnemyData) -> void:
	var m := EnemyManager.find(get_tree())
	Audio.play_at(&"boss_death", GameState.player_position)
	Audio.stinger(&"boss_defeated", -20.0)
	Events.announcement.emit("CHEFE DERROTADO: %s!" % data.display_name.to_upper(), Color(1, 0.85, 0.3))
	if m and m.current_boss() == null:
		_boss_active = false
		var back := _music_before_boss if _music_before_boss != &"" else GameState.setup.map.music_id
		await get_tree().create_timer(2.5, false).timeout
		if not _boss_active:
			Audio.play_music(back)


# --- Zumbis -----------------------------------------------------------------------

func _zombie_voices() -> void:
	var m := EnemyManager.find(get_tree())
	if m == null:
		return
	m.grid.query_radius(GameState.player_position, VOICE_RADIUS, _nearby)
	# Murmurio da horda: cresce com a quantidade de zumbis perto (um so loop).
	var crowd := _nearby.size()
	if crowd >= 8:
		Audio.start_loop(&"horde", &"zombie_horde_loop", linear_to_db(clampf(crowd / 60.0, 0.15, 1.0)))
	elif Audio.has_loop(&"horde"):
		Audio.stop_loop(&"horde", 1.0)
	if _nearby.is_empty():
		return
	# Algumas vozes individuais, vindas da posicao de zumbis proximos.
	for i: int in 2:
		var a := _nearby[_rng.randi_range(0, _nearby.size() - 1)]
		match a.data.behavior:
			EnemyData.Behavior.EXPLODER:
				Audio.play_at(&"zombie_bloater_gurgle", a.pos)
			_:
				if a.data.is_boss:
					continue
				if a.data.id == &"zombie_runner":
					if not _seen_runners.has(a.uid):
						_seen_runners[a.uid] = true
						Audio.play_at(&"zombie_runner_screech", a.pos)
				elif a.data.id == &"zombie_brute":
					Audio.play_at(&"zombie_brute_growl", a.pos)
				else:
					Audio.play_at(&"zombie_common_groan", a.pos)
	if _seen_runners.size() > 400:
		_seen_runners.clear()


func _on_damage(pos: Vector2, _amount: float, crit: bool) -> void:
	if crit:
		Audio.play_at(&"hit_crit", pos)
	else:
		Audio.play_at(&"hit_flesh", pos)


func _on_killed(a: EnemyAgent) -> void:
	if a.data.is_boss:
		return  # boss_killed cuida disso
	if a.elite:
		Audio.play_at(&"elite_death", a.pos)
	elif a.data.behavior != EnemyData.Behavior.EXPLODER:
		Audio.play_at(&"zombie_death", a.pos)


func _on_elite(_data: EnemyData) -> void:
	if _elite_alert_cooldown > 0.0:
		return
	_elite_alert_cooldown = 12.0
	Audio.play(&"elite_appear")
	Events.announcement.emit("ZUMBI DE ELITE!", Color(1, 0.82, 0.3))


# --- Jogador e coleta --------------------------------------------------------------

func _on_xp(_amount: int) -> void:
	# O tom sobe a cada gema coletada em sequencia (sensacao de progresso).
	_xp_combo = mini(_xp_combo + 1, 14)
	_xp_combo_timer = 0.7
	Audio.play(&"pickup_xp", 0.0, 1.0 + _xp_combo * 0.045)


func _on_health(current: float, max_value: float) -> void:
	_hp_ratio = current / maxf(1.0, max_value)
	if _hp_ratio < LOW_HP and current > 0.0:
		if not Audio.has_loop(&"heartbeat"):
			Audio.start_loop(&"heartbeat", &"player_heartbeat")
	elif Audio.has_loop(&"heartbeat"):
		Audio.stop_loop(&"heartbeat", 0.5)


func _on_event(kind: StringName, pos: Vector2) -> void:
	match kind:
		&"horde":
			Audio.play(&"alert_horde")
			Audio.duck(SoundCatalog.BUS_MUSIC, -8.0, 1.5)
		&"supply":
			Audio.play(&"alert_supply")
		&"toxic":
			Audio.play_at(&"alert_toxic", pos)


# --- Ambiente ----------------------------------------------------------------------

func _update_environment() -> void:
	var map := GameMap.find(get_tree())
	var region := &"city"
	if map is CityMap:
		region = (map as CityMap).region_at(GameState.player_position)
	match region:
		&"beach":
			Audio.set_ambience(&"amb_beach")
		&"hills":
			Audio.set_ambience(&"amb_hills")
		_:
			Audio.set_ambience(&"amb_city")


func _ambient_oneshot() -> void:
	var map := GameMap.find(get_tree())
	if not map is CityMap:
		return
	var city := map as CityMap
	var p := GameState.player_position
	var region := city.region_at(p)
	var around := p + Vector2.from_angle(_rng.randf() * TAU) * _rng.randf_range(10.0, 20.0)
	# Assinaturas dos pontos turisticos (discretas).
	if city.layout.cristo and region == &"hills" and _rng.randf() < 0.5:
		Audio.play_at(&"amb_bell", Vector2(p.x, p.y - 25.0))
		return
	if city.layout.sugarloaf and region == &"beach" and p.x > city.layout.half_extents.x * 0.2 \
			and _rng.randf() < 0.4:
		Audio.play_at(&"amb_creak", Vector2(p.x + 15.0, p.y + 20.0))
		return
	match region:
		&"beach":
			Audio.play_at(&"amb_gull", around)
		&"hills":
			Audio.play_at([&"amb_dog", &"amb_clank"][_rng.randi_range(0, 1)], around)
		_:
			Audio.play_at([&"amb_siren", &"amb_clank", &"amb_dog"][_rng.randi_range(0, 2)], around)
