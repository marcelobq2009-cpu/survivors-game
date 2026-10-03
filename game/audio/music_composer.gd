class_name MusicComposer
extends RefCounted
## Compoe as musicas do jogo (originais, geradas por codigo) com instrumentos
## de identidade brasileira: surdo, caixa, tamborim, agogo, ganza, berimbau e
## cuica, mais baixo, pads, lead e metais.
##
## Cada trilha tem CAMADAS de mesmo tamanho (loop perfeito). Tocadas juntas
## ficam sincronizadas; o jogo liga/desliga camadas para mudar a intensidade.
## A composicao e feita aos poucos (await) para nao travar o jogo.

## Milissegundos de trabalho por frame antes de "respirar" (nao travar a tela).
## Milissegundos de composicao por frame (maior na tela de carregamento,
## pequeno durante a partida para nao travar).
var frame_budget_ms: int = 6

## Definicao das trilhas: bpm, compassos e nomes das camadas (em ordem de intensidade).
const TRACKS: Dictionary = {
	&"menu": {"bpm": 84.0, "bars": 4, "layers": 2},
	&"loading": {"bpm": 84.0, "bars": 2, "layers": 1},
	&"music_game": {"bpm": 110.0, "bars": 4, "layers": 4},
	&"ranked": {"bpm": 124.0, "bars": 4, "layers": 3},
	&"boss": {"bpm": 132.0, "bars": 4, "layers": 2},
}
const STINGERS: PackedStringArray = ["victory", "defeat", "boss_intro", "boss_defeated"]

var _rng := RandomNumberGenerator.new()
var _inst: Dictionary = {}
var _frame_start: int = 0


func _init() -> void:
	_rng.seed = 1888  # mesma musica sempre (composicao fixa)


## Gera as camadas de uma trilha (Array de PackedFloat32Array).
func render_track(id: StringName) -> Array[PackedFloat32Array]:
	var def: Dictionary = TRACKS[id]
	var out: Array[PackedFloat32Array] = []
	for layer: int in int(def["layers"]):
		_frame_start = Time.get_ticks_msec()
		var buf := Synth.silence(_length(def))
		await _layer(id, layer, buf, float(def["bpm"]), int(def["bars"]))
		Synth.drive(buf, 1.3)
		out.append(buf)
	return out


func render_stinger(id: StringName) -> PackedFloat32Array:
	_frame_start = Time.get_ticks_msec()
	var out := PackedFloat32Array()
	match id:
		&"victory":
			out = Synth.silence(4.5)
			var notes := [60, 64, 67, 72, 76, 79, 84]
			for i: int in notes.size():
				Synth.mix_into(out, _brass(notes[i], 0.5 if i < notes.size() - 1 else 2.5), i * 0.11, 0.5)
				await _breathe()
			for t: float in [0.0, 0.33, 0.77, 1.1]:
				Synth.mix_into(out, _get(&"surdo"), t, 0.9)
			for t: float in [0.8, 0.95, 1.1, 1.25]:
				Synth.mix_into(out, _get(&"agogo_hi"), t, 0.4)
			Synth.mix_into(out, _pad([48, 52, 55, 60], 3.5), 0.8, 0.5)
		&"defeat":
			out = Synth.silence(4.0)
			var notes2 := [69, 65, 62, 57]
			for i: int in notes2.size():
				Synth.mix_into(out, _lead(notes2[i], 0.6), i * 0.4, 0.4)
			Synth.mix_into(out, _pad([45, 48, 52], 3.5), 0.2, 0.45)
			Synth.mix_into(out, _get(&"surdo"), 0.0, 1.0)
			Synth.mix_into(out, _get(&"surdo"), 1.6, 0.8)
		&"boss_intro":
			out = Synth.silence(3.0)
			Synth.mix_into(out, SfxRecipes.explosion(_rng), 0.0, 0.7)
			for i: int in 3:
				Synth.mix_into(out, _brass(36 + i * 3, 1.6), 0.4 + i * 0.12, 0.45)
			for t: float in [0.0, 0.45, 0.9, 1.15, 1.4]:
				Synth.mix_into(out, _get(&"surdo"), t, 1.0)
		&"boss_defeated":
			out = Synth.silence(3.0)
			for i: int in 4:
				Synth.mix_into(out, _brass([60, 67, 72, 79][i], 0.8 if i < 3 else 2.0), i * 0.15, 0.45)
			Synth.mix_into(out, _get(&"surdo"), 0.0, 0.9)
			Synth.mix_into(out, _get(&"agogo_hi"), 0.6, 0.5)
	await _breathe()
	return Synth.normalize(Synth.echo(out, 0.14, 0.3, 0.4), 0.9)


# --- Trilhas ------------------------------------------------------------------

func _length(def: Dictionary) -> float:
	return 60.0 / float(def["bpm"]) * 4.0 * int(def["bars"])


func _layer(id: StringName, layer: int, buf: PackedFloat32Array, bpm: float, bars: int) -> void:
	var step := 60.0 / bpm / 4.0  # semicolcheia
	match id:
		&"menu", &"loading":
			# Dm - Bb - Gm - A (tensao, misterio)
			var chords := [[50, 53, 57], [46, 50, 53], [43, 46, 50], [45, 49, 52]]
			if layer == 0:
				for bar: int in bars:
					_hit(buf, _pad(chords[bar % 4], step * 16), bar * 16, step, 0.38)
					for s: int in [0, 3, 6, 8, 11, 14]:
						var note := 50 if s % 2 == 0 else 52
						_hit(buf, _berimbau(note + (0 if bar % 2 == 0 else -2)), bar * 16 + s, step, 0.5)
					await _breathe()
			else:
				for bar: int in bars:
					_hit(buf, _get(&"surdo_soft"), bar * 16, step, 0.8)
					_hit(buf, _get(&"surdo_soft"), bar * 16 + 3, step, 0.5)
					for s: int in range(0, 16, 2):
						_hit(buf, _get(&"ganza"), bar * 16 + s, step, 0.18 if s % 4 else 0.28)
					await _breathe()
		&"music_game":
			# Am - F - C - G a 110 bpm. Camadas: 0 calma, 1 groove, 2 batucada, 3 climax.
			var chords := [[57, 60, 64], [53, 57, 60], [48, 52, 55], [55, 59, 62]]
			var roots := [45, 41, 36, 43]
			for bar: int in bars:
				var b := bar * 16
				match layer:
					0:
						_hit(buf, _pad(chords[bar], step * 16), b, step, 0.32)
						for s: int in range(0, 16, 2):
							_hit(buf, _get(&"ganza"), b + s, step, 0.14)
					1:
						_hit(buf, _get(&"surdo"), b + 4, step, 0.9)
						_hit(buf, _get(&"surdo"), b + 12, step, 0.9)
						_hit(buf, _get(&"surdo_muted"), b, step, 0.55)
						_hit(buf, _get(&"surdo_muted"), b + 8, step, 0.55)
						for s: int in [0, 6, 10]:
							_hit(buf, _bass(roots[bar], step * 3), b + s, step, 0.5)
					2:
						for s: int in 16:
							_hit(buf, _get(&"caixa"), b + s, step, 0.32 if s % 4 == 3 else 0.12)
						for s: int in [0, 3, 6, 10, 12]:
							_hit(buf, _get(&"tamborim"), b + s, step, 0.4)
						for s: int in [0, 2, 7, 10, 15]:
							_hit(buf, _get(&"agogo_hi"), b + s, step, 0.25)
						for s: int in [4, 12]:
							_hit(buf, _get(&"agogo_lo"), b + s, step, 0.25)
					3:
						var riff := [69, 72, 74, 76, 74, 72, 69, 67]
						for s: int in range(0, 16, 2):
							_hit(buf, _lead(riff[(s / 2 + bar * 3) % riff.size()], step * 1.6), b + s, step, 0.22)
						_hit(buf, Synth.drive(_bass(roots[bar] + 12, step * 8).duplicate(), 2.5), b, step, 0.3)
						if bar % 2 == 1:
							_hit(buf, _get(&"cuica"), b + 12, step, 0.4)
				await _breathe()
		&"ranked":
			# Em, pulso constante e competitivo (o relogio corre).
			var roots := [40, 40, 43, 38]
			for bar: int in bars:
				var b := bar * 16
				match layer:
					0:
						for s: int in range(0, 16, 2):
							_hit(buf, _bass(roots[bar], step * 1.6), b + s, step, 0.42)
						for s: int in 16:
							_hit(buf, _get(&"tick"), b + s, step, 0.16 if s % 4 == 0 else 0.07)
					1:
						for s: int in [0, 4, 8, 12]:
							_hit(buf, _get(&"kick"), b + s, step, 0.85)
						for s: int in [4, 12]:
							_hit(buf, _get(&"caixa"), b + s, step, 0.55)
						for s: int in range(2, 16, 4):
							_hit(buf, _get(&"ganza"), b + s, step, 0.25)
					2:
						var arp := [64, 67, 71, 76, 71, 67]
						for s: int in range(0, 16, 2):
							_hit(buf, _lead(arp[(s / 2 + bar) % arp.size()], step * 1.5), b + s, step, 0.2)
						for s: int in [0, 3, 8, 11]:
							_hit(buf, _get(&"agogo_hi" if s < 8 else &"agogo_lo"), b + s, step, 0.25)
				await _breathe()
		&"boss":
			# Cm pesado: surdo dobrado, baixo distorcido e metais.
			var riff := [36, 36, 39, 36, 41, 39, 34, 35]
			for bar: int in bars:
				var b := bar * 16
				if layer == 0:
					for s: int in range(0, 16, 2):
						_hit(buf, _get(&"surdo" if s % 4 == 0 else &"surdo_muted"), b + s, step, 0.85)
						_hit(buf, Synth.drive(_bass(riff[(s / 2) % riff.size()], step * 1.8).duplicate(), 3.0), b + s, step, 0.38)
				else:
					for s: int in [0, 6, 12]:
						_hit(buf, _brass(60 + [0, 3, -2][s / 6], step * 4), b + s, step, 0.3)
					for s: int in 16:
						_hit(buf, _get(&"caixa"), b + s, step, 0.3 if s >= 12 else 0.14)
				await _breathe()


# --- Instrumentos ---------------------------------------------------------------

func _get(name: StringName) -> PackedFloat32Array:
	if not _inst.has(name):
		_inst[name] = _make(name)
	return _inst[name]


func _make(name: StringName) -> PackedFloat32Array:
	match name:
		&"kick":
			var k := Synth.tone(65.0, 0.35, Synth.Wave.SINE, 0.001, 9.0, 1.0, 38.0)
			Synth.mix_into(k, Synth.noise(0.01, 0, 0.0005, 200.0, 0.4, _rng), 0.0)
			return k
		&"surdo":
			return Synth.tone(58.0, 0.7, Synth.Wave.SINE, 0.002, 4.5, 1.0, 48.0)
		&"surdo_soft":
			return Synth.lowpass(Synth.tone(55.0, 0.8, Synth.Wave.SINE, 0.01, 4.0, 0.8, 47.0), 300.0)
		&"surdo_muted":
			return Synth.tone(62.0, 0.18, Synth.Wave.SINE, 0.002, 20.0, 0.9, 50.0)
		&"caixa":
			var c := Synth.bandpass(Synth.noise(0.12, 0, 0.0005, 30.0, 0.9, _rng), 1500.0, 7000.0)
			Synth.mix_into(c, Synth.tone(210.0, 0.05, Synth.Wave.TRIANGLE, 0.001, 50.0, 0.4), 0.0)
			return c
		&"tamborim":
			var t := Synth.tone(1050.0, 0.06, Synth.Wave.SQUARE, 0.0005, 60.0, 0.5)
			Synth.mix_into(t, Synth.highpass(Synth.noise(0.02, 0, 0.0005, 150.0, 0.5, _rng), 3000.0), 0.0)
			return Synth.lowpass(t, 6000.0)
		&"ganza":
			return Synth.highpass(Synth.noise(0.07, 0, 0.02, 40.0, 0.6, _rng), 4500.0)
		&"agogo_hi":
			return _bell(920.0)
		&"agogo_lo":
			return _bell(690.0)
		&"cuica":
			var c2 := Synth.silence(0.4)
			var phase := 0.0
			for i: int in c2.size():
				var u := float(i) / c2.size()
				var f := 380.0 + 420.0 * sin(PI * minf(1.0, u * 1.6))
				phase += f * (1.0 + 0.03 * sin(TAU * 9.0 * u)) / Synth.RATE
				c2[i] = sin(TAU * phase) * sin(PI * u) * 0.8
			return Synth.bandpass(c2, 250.0, 2500.0)
		&"tick":
			return Synth.tone(2400.0, 0.02, Synth.Wave.SINE, 0.0005, 120.0, 0.6)
	return PackedFloat32Array()


func _bell(f: float) -> PackedFloat32Array:
	var b := Synth.tone(f, 0.3, Synth.Wave.SINE, 0.001, 12.0, 0.6)
	Synth.mix_into(b, Synth.tone(f * 2.7, 0.2, Synth.Wave.SINE, 0.001, 18.0, 0.25), 0.0)
	return b


func _bass(note: int, seconds: float) -> PackedFloat32Array:
	var key := "bass_%d_%.3f" % [note, seconds]
	if not _inst.has(key):
		_inst[key] = Synth.lowpass(Synth.tone(Synth.midi(note), seconds, Synth.Wave.SAW, 0.005, 3.0, 0.8), 450.0)
	return _inst[key]


func _lead(note: int, seconds: float) -> PackedFloat32Array:
	var key := "lead_%d_%.3f" % [note, seconds]
	if not _inst.has(key):
		_inst[key] = Synth.lowpass(Synth.tone(Synth.midi(note), seconds, Synth.Wave.SQUARE, 0.01, 3.0, 0.5, -1.0, 5.5, 0.006), 2400.0)
	return _inst[key]


func _brass(note: int, seconds: float) -> PackedFloat32Array:
	var a := Synth.tone(Synth.midi(note), seconds, Synth.Wave.SAW, 0.03, 1.5, 0.5)
	Synth.mix_into(a, Synth.tone(Synth.midi(note) * 1.006, seconds, Synth.Wave.SAW, 0.03, 1.5, 0.4), 0.0)
	return Synth.lowpass(Synth.drive(a, 1.6), 2200.0)


func _pad(notes: Array, seconds: float) -> PackedFloat32Array:
	var key := "pad_%s_%.3f" % [str(notes), seconds]
	if _inst.has(key):
		return _inst[key]
	var out := Synth.silence(seconds)
	for n: int in notes:
		for detune: float in [0.997, 1.003]:
			var v := Synth.tone(Synth.midi(n) * detune, seconds, Synth.Wave.SAW, seconds * 0.35, 0.4, 0.22)
			Synth.mix_into(out, v, 0.0)
	_inst[key] = Synth.lowpass(out, 1100.0)
	return _inst[key]


func _berimbau(note: int) -> PackedFloat32Array:
	var p := Synth.pluck(Synth.midi(note), 0.5, 0.8, 0.994, Synth.midi(note + 1), _rng)
	Synth.mix_into(p, Synth.highpass(Synth.noise(0.05, 0, 0.01, 40.0, 0.25, _rng), 4000.0), 0.0)  # caxixi
	return Synth.bandpass(p, 120.0, 3000.0)


## Coloca um som no passo `step_index` (semicolcheias), dando a volta no loop.
func _hit(buf: PackedFloat32Array, sound: PackedFloat32Array, step_index: int, step: float,
		gain: float) -> void:
	Synth.mix_wrap(buf, sound, int(step_index * step * Synth.RATE), gain)


## Se ja trabalhou demais neste frame, espera o proximo (nao trava a tela).
func _breathe() -> void:
	if Time.get_ticks_msec() - _frame_start > frame_budget_ms:
		await (Engine.get_main_loop() as SceneTree).process_frame
		_frame_start = Time.get_ticks_msec()
