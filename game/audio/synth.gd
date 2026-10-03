class_name Synth
extends RefCounted
## "Laboratorio de som": funcoes simples de sintese que geram audio em memoria
## (PackedFloat32Array mono, valores de -1 a 1). Todos os sons do jogo sao
## ORIGINAIS, criados por estas funcoes — sem risco de licenca.
## Para trocar por gravacoes reais, veja autoload/audio.gd (arquivos substituem
## os sons gerados automaticamente).

const RATE := 22050

enum Wave { SINE, SAW, SQUARE, TRIANGLE }


static func samples(seconds: float) -> int:
	return maxi(1, int(seconds * RATE))


static func silence(seconds: float) -> PackedFloat32Array:
	var a := PackedFloat32Array()
	a.resize(samples(seconds))
	return a


## Tom com envelope (ataque linear, queda exponencial), glissando opcional
## (freq -> freq_end) e vibrato.
static func tone(freq: float, seconds: float, wave: Wave = Wave.SINE, attack: float = 0.005,
		decay: float = 6.0, volume: float = 0.8, freq_end: float = -1.0,
		vibrato_hz: float = 0.0, vibrato_depth: float = 0.0) -> PackedFloat32Array:
	var n := samples(seconds)
	var out := PackedFloat32Array()
	out.resize(n)
	var phase := 0.0
	var a_n := maxf(1.0, attack * RATE)
	var f_end := freq if freq_end < 0.0 else freq_end
	for i: int in n:
		var t := float(i) / RATE
		var u := float(i) / n
		var f := lerpf(freq, f_end, u)
		if vibrato_hz > 0.0:
			f *= 1.0 + sin(TAU * vibrato_hz * t) * vibrato_depth
		phase += f / RATE
		var p := phase - floorf(phase)
		var v := 0.0
		match wave:
			Wave.SINE:
				v = sin(TAU * p)
			Wave.SAW:
				v = 2.0 * p - 1.0
			Wave.SQUARE:
				v = 1.0 if p < 0.5 else -1.0
			Wave.TRIANGLE:
				v = 4.0 * absf(p - 0.5) - 1.0
		var env := minf(1.0, i / a_n) * exp(-decay * t)
		out[i] = v * env * volume
	return out


## Ruido (0 = branco, 1 = rosado/suave, 2 = marrom/grave) com envelope.
static func noise(seconds: float, color: int = 0, attack: float = 0.002, decay: float = 10.0,
		volume: float = 0.8, rng: RandomNumberGenerator = null) -> PackedFloat32Array:
	var r := rng if rng else RandomNumberGenerator.new()
	var n := samples(seconds)
	var out := PackedFloat32Array()
	out.resize(n)
	var a_n := maxf(1.0, attack * RATE)
	var last := 0.0
	for i: int in n:
		var w := r.randf_range(-1.0, 1.0)
		match color:
			1:
				last = last * 0.8 + w * 0.2
				w = last * 2.2
			2:
				last = clampf(last + w * 0.06, -1.0, 1.0)
				w = last
		var t := float(i) / RATE
		out[i] = w * minf(1.0, i / a_n) * exp(-decay * t) * volume
	return out


## Corda dedilhada (Karplus-Strong): violao, berimbau, cavaquinho.
static func pluck(freq: float, seconds: float, volume: float = 0.8, damping: float = 0.996,
		bend_to: float = -1.0, rng: RandomNumberGenerator = null) -> PackedFloat32Array:
	var r := rng if rng else RandomNumberGenerator.new()
	var n := samples(seconds)
	var out := PackedFloat32Array()
	out.resize(n)
	var period := maxi(2, int(RATE / freq))
	var buf := PackedFloat32Array()
	buf.resize(period)
	for i: int in period:
		buf[i] = r.randf_range(-1.0, 1.0)
	var idx := 0
	var end_period := period if bend_to <= 0.0 else maxi(2, int(RATE / bend_to))
	for i: int in n:
		var cur_period := int(lerpf(period, end_period, minf(1.0, float(i) / (n * 0.3))))
		cur_period = clampi(cur_period, 2, period)
		var a := buf[idx % period]
		var b := buf[(idx + 1) % period]
		var v := (a + b) * 0.5 * damping
		buf[idx % period] = v
		out[i] = a * volume
		idx = (idx + 1) % cur_period
	return out


# --- Processamento (alteram o array no lugar) ----------------------------------

static func lowpass(a: PackedFloat32Array, cutoff: float) -> PackedFloat32Array:
	var k := clampf(TAU * cutoff / RATE, 0.0, 1.0)
	var y := 0.0
	for i: int in a.size():
		y += k * (a[i] - y)
		a[i] = y
	return a


static func highpass(a: PackedFloat32Array, cutoff: float) -> PackedFloat32Array:
	var k := clampf(TAU * cutoff / RATE, 0.0, 1.0)
	var low := 0.0
	for i: int in a.size():
		low += k * (a[i] - low)
		a[i] = a[i] - low
	return a


static func bandpass(a: PackedFloat32Array, low_cut: float, high_cut: float) -> PackedFloat32Array:
	return lowpass(highpass(a, low_cut), high_cut)


## Saturacao suave (mais "peso", tipo amplificador estourado).
static func drive(a: PackedFloat32Array, amount: float) -> PackedFloat32Array:
	var norm := 1.0 / tanh(amount)
	for i: int in a.size():
		a[i] = tanh(a[i] * amount) * norm
	return a


## Eco simples (da sensacao de espaco: rua, tunel, explosao distante).
static func echo(a: PackedFloat32Array, delay: float, feedback: float, mix: float,
		tail: float = 0.0) -> PackedFloat32Array:
	if tail > 0.0:
		a.append_array(silence(tail))
	var d := samples(delay)
	for i: int in range(d, a.size()):
		a[i] += a[i - d] * feedback * mix
	return a


## Tremolo (volume oscilando): sirenes, motores, buzinas.
static func tremolo(a: PackedFloat32Array, hz: float, depth: float) -> PackedFloat32Array:
	for i: int in a.size():
		a[i] *= 1.0 - depth * (0.5 + 0.5 * sin(TAU * hz * i / RATE))
	return a


## Soma `src` dentro de `dst` a partir de `at_seconds` (aumenta dst se precisar).
static func mix_into(dst: PackedFloat32Array, src: PackedFloat32Array, at_seconds: float,
		gain: float = 1.0) -> PackedFloat32Array:
	var off := int(at_seconds * RATE)
	if off + src.size() > dst.size():
		dst.resize(off + src.size())
	for i: int in src.size():
		dst[off + i] += src[i] * gain
	return dst


## Mistura que da a volta no fim (para loops perfeitos de musica).
static func mix_wrap(dst: PackedFloat32Array, src: PackedFloat32Array, at_sample: int,
		gain: float = 1.0) -> void:
	var n := dst.size()
	for i: int in src.size():
		var j := (at_sample + i) % n
		dst[j] += src[i] * gain


static func combine(parts: Array[PackedFloat32Array]) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	for p: PackedFloat32Array in parts:
		mix_into(out, p, 0.0)
	return out


static func normalize(a: PackedFloat32Array, peak: float = 0.9) -> PackedFloat32Array:
	var m := 0.0001
	for v: float in a:
		m = maxf(m, absf(v))
	var g := peak / m
	for i: int in a.size():
		a[i] *= g
	return a


## Suaviza inicio/fim (evita estalos).
static func fade_edges(a: PackedFloat32Array, fade_in: float = 0.002, fade_out: float = 0.01) -> PackedFloat32Array:
	var fi := mini(a.size(), samples(fade_in))
	var fo := mini(a.size(), samples(fade_out))
	for i: int in fi:
		a[i] *= float(i) / fi
	for i: int in fo:
		a[a.size() - 1 - i] *= float(i) / fo
	return a


## Converte para AudioStream do Godot (16 bits, mono).
static func to_stream(a: PackedFloat32Array, loop: bool = false, rate: int = RATE) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(a.size() * 2)
	for i: int in a.size():
		bytes.encode_s16(i * 2, int(clampf(a[i], -1.0, 1.0) * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.stereo = false
	wav.data = bytes
	if loop:
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = a.size()
	return wav


## Frequencia de uma nota MIDI (69 = La 440 Hz).
static func midi(note: int) -> float:
	return 440.0 * pow(2.0, (note - 69) / 12.0)
