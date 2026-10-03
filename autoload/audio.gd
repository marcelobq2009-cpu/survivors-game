extends Node
## AudioManager (autoload "Audio"): TODO o som do jogo passa por aqui.
##   play(id)                efeito (nao posicional)
##   play_at(id, pos)        efeito posicional 3D (esquerda/direita, distancia)
##   start_loop/stop_loop    sons continuos (gas, fogo, coracao, horda)
##   play_music(trilha)      troca de musica com crossfade
##   set_intensity(n)        camadas da musica (1 = calma ... 4 = climax)
##   stinger(id)             vinheta curta (vitoria, chefe...) abaixando a musica
##   duck(bus, db, s)        abaixa um canal por um tempo (level-up, evolucao)
##   set_ambience(regiao)    ambiente do mapa (cidade, orla, morro) com crossfade
##
## Otimizacao: numero fixo de "vozes" reaproveitadas, prioridade (sons
## importantes roubam a voz dos menos importantes), limite de copias e
## intervalo minimo por som. Os sons gerados por codigo sao guardados em cache
## (user://audio_cache) para abrir rapido nas proximas vezes.

const CACHE_DIR := "user://audio_cache/v3/"
const AUDIO_DIR := "res://assets/audio/"
const EXTENSIONS: PackedStringArray = ["ogg", "wav", "mp3"]
const VOICES_2D := 12
const VOICES_3D := 16
const VOICES_UI := 5
const BAKE_BUDGET_MS := 5
const MUSIC_FADE := 1.4
const SILENT_DB := -60.0
## Prioridade da ordem de preparo (o resto vem depois, em segundo plano).
const BAKE_FIRST: Array[StringName] = [&"ui_click", &"ui_select", &"ui_back", &"ui_transition"]
## Trilhas preparadas ja na abertura do jogo (o resto: na tela de carregamento).
const MUSIC_STARTUP: Array[StringName] = [&"menu", &"loading"]
const MUSIC_GAME: Array[StringName] = [&"music_game", &"ranked", &"boss"]

signal music_ready(track: StringName)

var catalog: Dictionary = {}
var _streams: Dictionary = {}       # id -> Array[AudioStream]
var _last_var: Dictionary = {}
var _last_ms: Dictionary = {}
var _bake_queue: Array[StringName] = []
var _voices_2d: Array[AudioStreamPlayer] = []
var _voices_ui: Array[AudioStreamPlayer] = []
var _voices_3d: Array[AudioStreamPlayer3D] = []
var _voice_info: Dictionary = {}    # player -> [id, priority]
var _loops: Dictionary = {}         # chave -> AudioStreamPlayer/3D
var _rng := RandomNumberGenerator.new()

# Musica
var _tracks: Dictionary = {}        # trilha -> Array[AudioStream] (camadas)
var _stingers: Dictionary = {}
var _music_players: Array[AudioStreamPlayer] = []
var _old_music: Array[AudioStreamPlayer] = []
var _music_id: StringName = &""
var _wanted_music: StringName = &""
var _intensity: int = 1
var _stinger_player: AudioStreamPlayer
var _music_duck_db: float = 0.0
var _music_duck_left: float = 0.0
var _composer := MusicComposer.new()
var _composing: bool = false

# Ambiente
var _amb_players: Array[AudioStreamPlayer] = []
var _amb_active: int = 0
var _ambience: StringName = &""

# Abaixar canais temporariamente
var _ducks: Dictionary = {}         # bus -> [db, segundos restantes]
var _was_paused: bool = false
var _settings: GameSettings
var _combat_music_reduce: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rng.randomize()
	DirAccess.make_dir_recursive_absolute(CACHE_DIR)
	_ensure_buses()
	catalog = SoundCatalog.build()
	for i: int in VOICES_2D:
		_voices_2d.append(_make_player(true))
	for i: int in VOICES_UI:
		_voices_ui.append(_make_player(false))
	for i: int in VOICES_3D:
		var p := AudioStreamPlayer3D.new()
		p.process_mode = Node.PROCESS_MODE_PAUSABLE
		p.unit_size = 9.0
		p.max_distance = 55.0
		p.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
		add_child(p)
		_voices_3d.append(p)
	_stinger_player = _make_player(false)
	_stinger_player.bus = SoundCatalog.BUS_MUSIC
	for i: int in 2:
		var a := _make_player(true)
		a.bus = SoundCatalog.BUS_AMBIENCE
		a.volume_db = SILENT_DB
		_amb_players.append(a)
	# Na abertura so os sons da interface (o resto e preparado no carregamento
	# da partida, onde uma pequena espera e natural).
	for id: StringName in BAKE_FIRST:
		_bake_queue.append(id)
	for id: StringName in catalog:
		if String(id).begins_with("ui_") and not _bake_queue.has(id):
			_bake_queue.append(id)
	apply_settings(Save.profile.settings)
	Save.profile_changed.connect(func() -> void: apply_settings(Save.profile.settings))
	_compose_all.call_deferred()


func _make_player(pausable: bool) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.process_mode = Node.PROCESS_MODE_PAUSABLE if pausable else Node.PROCESS_MODE_ALWAYS
	add_child(p)
	return p


# --- Efeitos ----------------------------------------------------------------------

## Toca um efeito nao posicional. `pitch` multiplica o tom (ex.: combo de XP).
func play(id: StringName, volume_offset_db: float = 0.0, pitch: float = 1.0) -> void:
	var def := _def(id)
	if def == null or not _allowed(def):
		return
	var stream := _pick_stream(def)
	if stream == null:
		return
	var pool := _voices_ui if def.bus == SoundCatalog.BUS_UI else _voices_2d
	var p := _take_voice(pool, def) as AudioStreamPlayer
	if p == null:
		return
	p.stream = stream
	p.bus = def.bus
	p.volume_db = def.volume_db + volume_offset_db
	p.pitch_scale = pitch * _rng.randf_range(1.0 - def.pitch_var, 1.0 + def.pitch_var)
	p.play()
	_caption(def)


## Toca um efeito posicional no ponto `pos` do chao (Vector2).
func play_at(id: StringName, pos: Vector2, volume_offset_db: float = 0.0, height: float = 1.0) -> void:
	var def := _def(id)
	if def == null:
		return
	if not def.spatial or _settings == null:
		play(id, volume_offset_db)
		return
	if not _allowed(def):
		return
	var stream := _pick_stream(def)
	if stream == null:
		return
	var p := _take_voice(_voices_3d, def) as AudioStreamPlayer3D
	if p == null:
		return
	p.stream = stream
	p.bus = def.bus
	p.global_position = GroundPlane.to_3d(pos, height)
	p.volume_db = def.volume_db + volume_offset_db
	p.pitch_scale = _rng.randf_range(1.0 - def.pitch_var, 1.0 + def.pitch_var)
	p.panning_strength = 0.0 if _settings.mono_audio else 1.0
	p.play()
	_caption(def)


## Som continuo identificado por `key`. Com `pos`, fica posicional.
func start_loop(key: StringName, id: StringName, volume_offset_db: float = 0.0,
		pos: Variant = null) -> void:
	var def := _def(id)
	if def == null:
		return
	var stream := _pick_stream(def)
	if stream == null:
		return
	if _loops.has(key):
		set_loop_volume(key, def.volume_db + volume_offset_db)
		if pos is Vector2 and _loops[key] is AudioStreamPlayer3D:
			(_loops[key] as AudioStreamPlayer3D).global_position = GroundPlane.to_3d(pos as Vector2, 1.0)
		return
	var p: Node
	if pos is Vector2:
		var p3 := AudioStreamPlayer3D.new()
		p3.unit_size = 8.0
		p3.max_distance = 45.0
		p3.global_position = GroundPlane.to_3d(pos as Vector2, 1.0)
		p3.stream = stream
		p3.bus = def.bus
		p3.volume_db = def.volume_db + volume_offset_db
		p3.process_mode = Node.PROCESS_MODE_PAUSABLE
		add_child(p3)
		p3.play()
		p = p3
	else:
		var p2 := _make_player(true)
		p2.stream = stream
		p2.bus = def.bus
		p2.volume_db = def.volume_db + volume_offset_db
		p2.play()
		p = p2
	_loops[key] = p
	_caption(def)


func set_loop_volume(key: StringName, volume_db: float) -> void:
	var p: Node = _loops.get(key)
	if p is AudioStreamPlayer:
		(p as AudioStreamPlayer).volume_db = volume_db
	elif p is AudioStreamPlayer3D:
		(p as AudioStreamPlayer3D).volume_db = volume_db


func set_loop_position(key: StringName, pos: Vector2) -> void:
	var p: Node = _loops.get(key)
	if p is AudioStreamPlayer3D:
		(p as AudioStreamPlayer3D).global_position = GroundPlane.to_3d(pos, 1.0)


func has_loop(key: StringName) -> bool:
	return _loops.has(key)


func stop_loop(key: StringName, fade: float = 0.3) -> void:
	var p: Node = _loops.get(key)
	if p == null:
		return
	_loops.erase(key)
	var tw := create_tween()
	tw.tween_property(p, "volume_db", SILENT_DB, fade)
	tw.tween_callback(p.queue_free)


## Para todos os loops (fim de partida / troca de cena).
func stop_all_loops() -> void:
	for key: StringName in _loops.keys():
		stop_loop(key, 0.4)


## Abaixa um canal por `seconds` (ex.: efeitos durante o level-up).
func duck(bus: StringName, db: float, seconds: float) -> void:
	_ducks[bus] = [db, seconds]


# --- Musica -------------------------------------------------------------------------

func play_music(track: StringName) -> void:
	_wanted_music = track
	if track == _music_id:
		return
	if not _tracks.has(track):
		return  # Ainda sendo composta; toca assim que ficar pronta (music_ready).
	_switch_music(track)


func stop_music() -> void:
	_wanted_music = &""
	_switch_music(&"")


## Quantas camadas da musica atual tocam (1 = calma ... 4 = climax).
func set_intensity(level: int) -> void:
	_intensity = maxi(1, level)


func intensity() -> int:
	return _intensity


func current_music() -> StringName:
	return _music_id


## Vinheta curta (vitoria, chefe, derrota). Abaixa a musica enquanto toca.
func stinger(id: StringName, duck_db: float = -14.0) -> void:
	var s: AudioStream = _stingers.get(id)
	if s == null:
		return
	_stinger_player.stream = s
	_stinger_player.volume_db = -2.0
	_stinger_player.play()
	_music_duck_db = duck_db
	_music_duck_left = s.get_length()


func _switch_music(track: StringName) -> void:
	for p: AudioStreamPlayer in _music_players:
		_old_music.append(p)
	_music_players.clear()
	_music_id = track
	if track == &"":
		return
	var layers: Array = _tracks[track]
	for i: int in layers.size():
		var p := _make_player(false)
		p.bus = SoundCatalog.BUS_MUSIC
		p.stream = layers[i]
		p.volume_db = SILENT_DB
		_music_players.append(p)
	# Todas as camadas comecam juntas (ficam sincronizadas para sempre).
	for p: AudioStreamPlayer in _music_players:
		p.play()


func _update_music(delta: float) -> void:
	var step := delta * (-SILENT_DB) / MUSIC_FADE
	_music_duck_left = maxf(0.0, _music_duck_left - delta)
	var duck_db := _music_duck_db if _music_duck_left > 0.0 else 0.0
	for i: int in _music_players.size():
		var p := _music_players[i]
		var target := (0.0 if i < _intensity else SILENT_DB) + duck_db - 4.0
		p.volume_db = move_toward(p.volume_db, target, step)
	for p: AudioStreamPlayer in _old_music.duplicate():
		p.volume_db = move_toward(p.volume_db, SILENT_DB, step)
		if p.volume_db <= SILENT_DB + 0.1:
			_old_music.erase(p)
			p.queue_free()


# --- Ambiente -------------------------------------------------------------------------

## Troca o som de fundo (amb_city, amb_beach, amb_hills ou &"" para silencio).
func set_ambience(id: StringName) -> void:
	if id == _ambience:
		return
	_ambience = id
	_amb_active = 1 - _amb_active
	var p := _amb_players[_amb_active]
	if id != &"":
		var def := _def(id)
		var s: AudioStream = _pick_stream(def) if def else null
		if s:
			p.stream = s
			p.play()


func _update_ambience(delta: float) -> void:
	for i: int in _amb_players.size():
		var p := _amb_players[i]
		var def: SoundCatalog.Def = _def(_ambience) if _ambience != &"" else null
		var target := (def.volume_db if def else SILENT_DB) if i == _amb_active else SILENT_DB
		p.volume_db = move_toward(p.volume_db, target, delta * 30.0)
		if p.volume_db <= SILENT_DB + 0.1 and p.playing and i != _amb_active:
			p.stop()


# --- Configuracoes ----------------------------------------------------------------------

func apply_settings(s: GameSettings) -> void:
	_settings = s
	_set_bus(&"Master", s.master_volume, s.music_on or s.sfx_on, s.mute_all)
	_set_bus(SoundCatalog.BUS_MUSIC, s.music_volume, s.music_on)
	_set_bus(SoundCatalog.BUS_SFX, s.sfx_volume, s.sfx_on)
	_set_bus(SoundCatalog.BUS_AMBIENCE, s.ambience_volume, s.sfx_on)
	_set_bus(SoundCatalog.BUS_ZOMBIES, s.zombies_volume, s.sfx_on)
	_set_bus(SoundCatalog.BUS_UI, s.ui_volume, s.sfx_on)
	_set_bus(SoundCatalog.BUS_BOSSES, s.bosses_volume, s.sfx_on)
	_set_bus(SoundCatalog.BUS_ALERTS, s.alerts_volume * (1.6 if s.boost_alerts else 1.0), s.sfx_on)
	# "Reduzir sons intensos": limitador mais forte no Master.
	var limiter := AudioServer.get_bus_effect(0, 0) as AudioEffectHardLimiter
	if limiter:
		limiter.ceiling_db = -6.0 if s.reduce_intense else -0.5
	for p: AudioStreamPlayer3D in _voices_3d:
		p.panning_strength = 0.0 if s.mono_audio else 1.0


## Durante a partida, a opcao "musica mais baixa no combate" abaixa a musica.
func set_combat_music(active: bool) -> void:
	_combat_music_reduce = active


func vibrate(ms: int) -> void:
	if _settings and _settings.vibration and (OS.has_feature("mobile") or OS.has_feature("web")):
		Input.vibrate_handheld(ms)


## Toca uma amostra de cada categoria (botao "Testar audio" das configuracoes).
func test_sequence() -> void:
	var seq: Array[StringName] = [&"ui_select", &"weapon_pistol_fire", &"zombie_common_groan",
			&"boss_colossus_roar", &"level_up", &"amb_gull"]
	for id: StringName in seq:
		play(id)
		await get_tree().create_timer(0.7, true, false, true).timeout


func _set_bus(bus: StringName, volume: float, on: bool, force_mute: bool = false) -> void:
	var idx := AudioServer.get_bus_index(bus)
	if idx < 0:
		return
	AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(0.0001, volume)))
	AudioServer.set_bus_mute(idx, force_mute or not on or volume <= 0.001)


func _ensure_buses() -> void:
	# Master: limitador (evita estouro quando muitos sons tocam juntos).
	if AudioServer.get_bus_effect_count(0) == 0:
		var lim := AudioEffectHardLimiter.new()
		lim.ceiling_db = -0.5
		AudioServer.add_bus_effect(0, lim)
	for bus: StringName in [SoundCatalog.BUS_MUSIC, SoundCatalog.BUS_SFX, SoundCatalog.BUS_AMBIENCE,
			SoundCatalog.BUS_ZOMBIES, SoundCatalog.BUS_UI, SoundCatalog.BUS_BOSSES, SoundCatalog.BUS_ALERTS]:
		if AudioServer.get_bus_index(bus) < 0:
			AudioServer.add_bus()
			var idx := AudioServer.bus_count - 1
			AudioServer.set_bus_name(idx, bus)
			AudioServer.set_bus_send(idx, &"Master")
	# Musica: filtro "abafado" usado na pausa.
	var mi := AudioServer.get_bus_index(SoundCatalog.BUS_MUSIC)
	if AudioServer.get_bus_effect_count(mi) == 0:
		var lp := AudioEffectLowPassFilter.new()
		lp.cutoff_hz = 900.0
		AudioServer.add_bus_effect(mi, lp)
		AudioServer.set_bus_effect_enabled(mi, 0, false)


# --- Loop principal: pausa, abaixar canais, musica, preparo em segundo plano ----

func _process(delta: float) -> void:
	var paused := get_tree().paused
	if paused != _was_paused:
		_was_paused = paused
		var mi := AudioServer.get_bus_index(SoundCatalog.BUS_MUSIC)
		AudioServer.set_bus_effect_enabled(mi, 0, paused)
	_update_ducks(delta)
	_update_music(delta)
	_update_ambience(delta)
	_bake_some()


func _update_ducks(delta: float) -> void:
	for bus: StringName in [SoundCatalog.BUS_SFX, SoundCatalog.BUS_ZOMBIES, SoundCatalog.BUS_AMBIENCE,
			SoundCatalog.BUS_MUSIC]:
		var idx := AudioServer.get_bus_index(bus)
		if idx < 0 or _settings == null:
			continue
		var base := _bus_base_volume(bus)
		var extra := 0.0
		if _ducks.has(bus):
			var d: Array = _ducks[bus]
			d[1] = float(d[1]) - delta
			extra = float(d[0])
			if float(d[1]) <= 0.0:
				_ducks.erase(bus)
		if bus == SoundCatalog.BUS_MUSIC:
			if _was_paused:
				extra -= 6.0
			if _combat_music_reduce and _settings.reduce_music_in_combat:
				extra -= 7.0
		var target := linear_to_db(maxf(0.0001, base)) + extra
		var current := AudioServer.get_bus_volume_db(idx)
		AudioServer.set_bus_volume_db(idx, move_toward(current, target, delta * 40.0))


func _bus_base_volume(bus: StringName) -> float:
	match bus:
		SoundCatalog.BUS_SFX:
			return _settings.sfx_volume
		SoundCatalog.BUS_ZOMBIES:
			return _settings.zombies_volume
		SoundCatalog.BUS_AMBIENCE:
			return _settings.ambience_volume
		SoundCatalog.BUS_MUSIC:
			return _settings.music_volume
	return 1.0


# --- Vozes, prioridade e variacoes -------------------------------------------------------

func _def(id: StringName) -> SoundCatalog.Def:
	return catalog.get(id) as SoundCatalog.Def


func _allowed(def: SoundCatalog.Def) -> bool:
	var now := Time.get_ticks_msec()
	if now - int(_last_ms.get(def.id, -100000)) < def.cooldown_ms:
		return false
	var playing := 0
	for p: Node in _voice_info:
		if _is_playing(p) and _voice_info[p][0] == def.id:
			playing += 1
	if playing >= def.max_instances:
		return false
	_last_ms[def.id] = now
	return true


## Pega uma voz livre; se nao houver, rouba a de menor prioridade (se for menor que a nossa).
func _take_voice(pool: Array, def: SoundCatalog.Def) -> Node:
	var victim: Node = null
	var victim_prio := def.priority
	for p: Node in pool:
		if not _is_playing(p):
			_voice_info[p] = [def.id, def.priority]
			return p
		var prio: int = _voice_info.get(p, [&"", 0])[1]
		if prio < victim_prio:
			victim_prio = prio
			victim = p
	if victim:
		victim.call(&"stop")
		_voice_info[victim] = [def.id, def.priority]
	return victim


func _is_playing(p: Node) -> bool:
	return p.get(&"playing") == true


## Sorteia uma variacao (nunca a mesma duas vezes seguidas).
func _pick_stream(def: SoundCatalog.Def) -> AudioStream:
	if not _streams.has(def.id):
		_bake(def.id)
	var list: Array = _streams.get(def.id, [])
	if list.is_empty():
		return null
	var i := _rng.randi_range(0, list.size() - 1)
	if list.size() > 1 and i == int(_last_var.get(def.id, -1)):
		i = (i + 1) % list.size()
	_last_var[def.id] = i
	return list[i]


func _caption(def: SoundCatalog.Def) -> void:
	if def.caption != "" and _settings and _settings.captions:
		Events.audio_caption.emit(def.caption)


# --- Preparo (gera ou carrega os sons) ---------------------------------------------------

func _bake_some() -> void:
	var start := Time.get_ticks_msec()
	while not _bake_queue.is_empty() and Time.get_ticks_msec() - start < BAKE_BUDGET_MS:
		var id: StringName = _bake_queue.pop_front()
		if not _streams.has(id):
			_bake(id)


## Prepara as variacoes de um som: 1) arquivos em assets/audio, 2) cache, 3) gera.
func _bake(id: StringName) -> void:
	var def := _def(id)
	if def == null:
		return
	var list: Array[AudioStream] = _load_files(def)
	if list.is_empty():
		for v: int in def.variations:
			var cache := "%s%s_%d.res" % [CACHE_DIR, id, v]
			var s: AudioStream = null
			if ResourceLoader.exists(cache):
				s = load(cache) as AudioStream
			if s == null:
				var rng := RandomNumberGenerator.new()
				rng.seed = hash(String(id)) + v * 7919
				var data: PackedFloat32Array = def.recipe.call(rng)
				var wav := Synth.to_stream(data, def.loop)
				ResourceSaver.save(wav, cache)
				s = wav
			list.append(s)
	_streams[id] = list


func _load_files(def: SoundCatalog.Def) -> Array[AudioStream]:
	var out: Array[AudioStream] = []
	var folder: String = AUDIO_DIR + String(SoundCatalog.FOLDERS.get(def.bus, "sfx")) + "/"
	for n: int in range(1, 9):
		for ext: String in EXTENSIONS:
			var path := "%s%s_%02d.%s" % [folder, def.id, n, ext]
			if ResourceLoader.exists(path):
				out.append(load(path) as AudioStream)
	return out


## Compoe (ou carrega do cache) todas as musicas, em segundo plano, por ordem de uso.
func _compose_all() -> void:
	if _composing:
		return
	_composing = true
	for track: StringName in MUSIC_STARTUP:
		await _prepare_track(track)
		if _wanted_music == track and _music_id != track:
			_switch_music(track)
		music_ready.emit(track)
	_composing = false


## Prepara (gera ou carrega do cache) tudo que a partida usa: efeitos, musicas
## da partida e vinhetas. Chamado pela tela de carregamento; `progress` recebe
## (0..1, texto). Rapido depois da primeira vez (cache).
func prepare_for_game(progress: Callable = Callable()) -> void:
	while _composing:
		await get_tree().process_frame
	var ids: Array[StringName] = []
	for id: StringName in catalog:
		if not _streams.has(id):
			ids.append(id)
	var total := ids.size() + MUSIC_GAME.size() + MusicComposer.STINGERS.size()
	var done := 0
	var frame_start := Time.get_ticks_msec()
	for id: StringName in ids:
		_bake(id)
		done += 1
		if Time.get_ticks_msec() - frame_start > 12:
			if progress.is_valid():
				progress.call(float(done) / total, "Afinando a batucada")
			await get_tree().process_frame
			frame_start = Time.get_ticks_msec()
	for track: StringName in MUSIC_GAME:
		if not _tracks.has(track):
			await _prepare_track(track)
		done += 1
		if progress.is_valid():
			progress.call(float(done) / total, "Compondo a trilha")
		if _wanted_music == track and _music_id != track:
			_switch_music(track)
	await _prepare_stingers()
	if progress.is_valid():
		progress.call(1.0, "Pronto")


func _prepare_stingers() -> void:
	for id: String in MusicComposer.STINGERS:
		var sid := StringName(id)
		var file := _music_file(sid, 1)
		if file:
			_stingers[sid] = file
			continue
		var cache := "%sstinger_%s.res" % [CACHE_DIR, id]
		if ResourceLoader.exists(cache):
			_stingers[sid] = load(cache)
		else:
			var data := await _composer.render_stinger(sid)
			var wav := Synth.to_stream(data)
			ResourceSaver.save(wav, cache)
			_stingers[sid] = wav


func _prepare_track(track: StringName) -> void:
	var layers: Array[AudioStream] = []
	var def: Dictionary = MusicComposer.TRACKS[track]
	var count := int(def["layers"])
	# 1) Arquivos reais (assets/audio/music/<trilha>_01.ogg = camada 1 ...).
	for i: int in count:
		var f := _music_file(track, i + 1)
		if f:
			layers.append(f)
	if layers.size() == count:
		_tracks[track] = layers
		return
	layers.clear()
	# 2) Cache. 3) Compor.
	var cached := true
	for i: int in count:
		var cache := "%smusic_%s_%d.res" % [CACHE_DIR, track, i]
		if not ResourceLoader.exists(cache):
			cached = false
			break
		layers.append(load(cache) as AudioStream)
	if not cached:
		layers.clear()
		var data := await _composer.render_track(track)
		for i: int in data.size():
			var wav := Synth.to_stream(data[i], true)
			ResourceSaver.save(wav, "%smusic_%s_%d.res" % [CACHE_DIR, track, i])
			layers.append(wav)
			await get_tree().process_frame
	_tracks[track] = layers


func _music_file(id: StringName, n: int) -> AudioStream:
	for ext: String in EXTENSIONS:
		var path := "%smusic/%s_%02d.%s" % [AUDIO_DIR, id, n, ext]
		if ResourceLoader.exists(path):
			return load(path) as AudioStream
	return null
