extends Node
## Audio do jogo (autoload "Audio"): musica + efeitos, com canais (buses)
## separados que respeitam as Configuracoes.
##
## Como trocar um som: coloque um arquivo em assets/audio/ com o MESMO nome do
## id (ex.: assets/audio/shoot.ogg ou .wav). Ele substitui o placeholder
## automaticamente, sem mexer em codigo. Sem arquivo, tocamos um som simples
## gerado por codigo (placeholder) para os efeitos; musica fica em silencio.

const AUDIO_DIR := "res://assets/audio/"
const EXTENSIONS: PackedStringArray = ["ogg", "wav", "mp3"]
const MAX_VOICES := 12
const MUSIC_BUS := &"Music"
const SFX_BUS := &"SFX"

## Ids de efeitos e o "timbre" do placeholder: [frequencia Hz, duracao s, tipo]
## tipo: 0 = bipe, 1 = ruido (impacto/explosao), 2 = arpejo (recompensa)
const SFX_PLACEHOLDERS: Dictionary = {
	&"shoot": [880.0, 0.05, 0], &"shotgun": [220.0, 0.12, 1], &"smg": [1200.0, 0.03, 0],
	&"melee": [300.0, 0.08, 1], &"throw": [500.0, 0.08, 0], &"explosion": [80.0, 0.35, 1],
	&"hit": [180.0, 0.05, 1], &"enemy_die": [140.0, 0.08, 1], &"player_hurt": [110.0, 0.15, 1],
	&"pickup_xp": [1500.0, 0.04, 0], &"pickup_gold": [1900.0, 0.06, 2], &"chest": [660.0, 0.35, 2],
	&"level_up": [520.0, 0.4, 2], &"boss": [70.0, 0.8, 1], &"horde": [90.0, 0.5, 1],
	&"victory": [440.0, 0.8, 2], &"defeat": [160.0, 0.7, 0], &"unlock": [700.0, 0.5, 2],
	&"record": [800.0, 0.6, 2], &"click": [1000.0, 0.03, 0], &"evolve": [600.0, 0.6, 2],
}
## Musicas (so tocam se o arquivo existir em assets/audio/).
const MUSIC_IDS: PackedStringArray = ["music_menu", "music_game", "music_boss"]

var _streams: Dictionary = {}  # StringName -> AudioStream
var _players: Array[AudioStreamPlayer] = []
var _next: int = 0
var _music: AudioStreamPlayer
var _music_id: StringName = &""
var _last_play_ms: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_buses()
	for id: StringName in SFX_PLACEHOLDERS:
		_streams[id] = _load_file(id)
		if _streams[id] == null:
			_streams[id] = _synth(SFX_PLACEHOLDERS[id] as Array)
	for id: String in MUSIC_IDS:
		var s := _load_file(StringName(id))
		if s:
			_streams[StringName(id)] = s
	for i: int in MAX_VOICES:
		var p := AudioStreamPlayer.new()
		p.bus = SFX_BUS
		add_child(p)
		_players.append(p)
	_music = AudioStreamPlayer.new()
	_music.bus = MUSIC_BUS
	add_child(_music)
	apply_settings(Save.profile.settings)
	Save.profile_changed.connect(func() -> void: apply_settings(Save.profile.settings))


## Toca um efeito. Ignora repeticoes muito rapidas do mesmo som (evita "metralhar").
func play(id: StringName, volume_db: float = 0.0) -> void:
	var stream: AudioStream = _streams.get(id)
	if stream == null:
		return
	var now := Time.get_ticks_msec()
	if now - int(_last_play_ms.get(id, -1000)) < 45:
		return
	_last_play_ms[id] = now
	var p := _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = stream
	p.volume_db = volume_db
	p.pitch_scale = randf_range(0.94, 1.06)
	p.play()


func play_music(id: StringName) -> void:
	if id == _music_id:
		return
	_music_id = id
	var stream: AudioStream = _streams.get(id)
	_music.stop()
	if stream:
		_music.stream = stream
		_music.play()


func vibrate(ms: int) -> void:
	if Save.profile.settings.vibration and (OS.has_feature("mobile") or OS.has_feature("web")):
		Input.vibrate_handheld(ms)


func apply_settings(s: GameSettings) -> void:
	_set_bus(&"Master", s.master_volume, true)
	_set_bus(MUSIC_BUS, s.music_volume, s.music_on)
	_set_bus(SFX_BUS, s.sfx_volume, s.sfx_on)


func _set_bus(bus: StringName, volume: float, on: bool) -> void:
	var idx := AudioServer.get_bus_index(bus)
	if idx < 0:
		return
	AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(0.0001, volume)))
	AudioServer.set_bus_mute(idx, not on or volume <= 0.001)


func _ensure_buses() -> void:
	for bus: StringName in [MUSIC_BUS, SFX_BUS]:
		if AudioServer.get_bus_index(bus) < 0:
			AudioServer.add_bus()
			var idx := AudioServer.bus_count - 1
			AudioServer.set_bus_name(idx, bus)
			AudioServer.set_bus_send(idx, &"Master")


func _load_file(id: StringName) -> AudioStream:
	for ext: String in EXTENSIONS:
		var path := "%s%s.%s" % [AUDIO_DIR, id, ext]
		if ResourceLoader.exists(path):
			return load(path) as AudioStream
	return null


## Gera um som curto (placeholder) em memoria.
func _synth(spec: Array) -> AudioStreamWAV:
	var freq: float = spec[0]
	var length: float = spec[1]
	var kind: int = spec[2]
	var rate := 22050
	var n := int(rate * length)
	var data := PackedByteArray()
	data.resize(n * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(freq)
	for i: int in n:
		var t := float(i) / rate
		var env := pow(1.0 - float(i) / n, 2.0)
		var v := 0.0
		match kind:
			0:
				v = sin(TAU * freq * t * (1.0 - 0.3 * t / length))
			1:
				v = rng.randf_range(-1.0, 1.0) * 0.8 + sin(TAU * freq * t) * 0.4
			2:
				var step := floori(t / length * 3.0)
				v = sin(TAU * freq * pow(1.26, step) * t)
		var sample := int(clampf(v * env * 0.5, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, sample)
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.stereo = false
	wav.data = data
	return wav
