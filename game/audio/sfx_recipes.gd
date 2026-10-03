class_name SfxRecipes
extends RefCounted
## Receitas dos efeitos sonoros (cada chamada gera UMA variacao, usando o rng).
## Nomes seguem o padrao do catalogo (game/audio/sound_catalog.gd).



# --- Armas ----------------------------------------------------------------------

## Pistola: estalo seco e rapido.
static func pistol(r: RandomNumberGenerator) -> PackedFloat32Array:
	var crack := Synth.bandpass(Synth.noise(0.12, 0, 0.0005, 38.0, 0.9, r), 900.0, 7000.0)
	var body := Synth.tone(r.randf_range(150, 175), 0.12, Synth.Wave.SINE, 0.001, 30.0, 0.7, 70.0)
	var tail := Synth.lowpass(Synth.noise(0.25, 1, 0.001, 14.0, 0.25, r), 1800.0)
	return Synth.normalize(Synth.fade_edges(Synth.combine([crack, body, tail] as Array[PackedFloat32Array])), 0.85)


## Espingarda: estrondo grave e longo + chumbo espalhando.
static func shotgun(r: RandomNumberGenerator) -> PackedFloat32Array:
	var blast := Synth.drive(Synth.lowpass(Synth.noise(0.45, 1, 0.0005, 9.0, 1.0, r), 2600.0), 2.2)
	var thump := Synth.tone(r.randf_range(80, 95), 0.3, Synth.Wave.SINE, 0.001, 12.0, 0.9, 40.0)
	var pump := Synth.bandpass(Synth.noise(0.06, 0, 0.001, 50.0, 0.4, r), 2000.0, 6000.0)
	var out := Synth.combine([blast, thump] as Array[PackedFloat32Array])
	Synth.mix_into(out, pump, 0.32)
	return Synth.normalize(Synth.fade_edges(Synth.echo(out, 0.09, 0.3, 0.5)), 0.95)


## Metralhadora: tiro curto e leve (toca muitas vezes; precisa ser discreto).
static func smg(r: RandomNumberGenerator) -> PackedFloat32Array:
	var crack := Synth.bandpass(Synth.noise(0.06, 0, 0.0005, 60.0, 0.8, r), 1400.0, 6500.0)
	var body := Synth.tone(r.randf_range(200, 240), 0.06, Synth.Wave.TRIANGLE, 0.001, 50.0, 0.5, 120.0)
	return Synth.normalize(Synth.fade_edges(Synth.combine([crack, body] as Array[PackedFloat32Array])), 0.6)


## Facao: "swish" do movimento.
static func machete_swing(r: RandomNumberGenerator) -> PackedFloat32Array:
	var n := Synth.noise(0.22, 0, 0.06, 6.0, 0.8, r)
	var out := Synth.silence(0.22)
	var lp := 0.0
	for i: int in n.size():
		var cut := lerpf(500.0, 4500.0, sin(PI * float(i) / n.size()))
		var k := clampf(TAU * cut / Synth.RATE, 0.0, 1.0)
		lp += k * (n[i] - lp)
		out[i] = lp
	return Synth.normalize(Synth.fade_edges(out), 0.7)


## Facao acertando: corte + pancada.
static func machete_hit(r: RandomNumberGenerator) -> PackedFloat32Array:
	var chop := Synth.bandpass(Synth.noise(0.1, 0, 0.0005, 30.0, 0.9, r), 300.0, 3000.0)
	var ring := Synth.tone(r.randf_range(1800, 2300), 0.15, Synth.Wave.SINE, 0.001, 25.0, 0.2)
	return Synth.normalize(Synth.fade_edges(Synth.combine([chop, ring] as Array[PackedFloat32Array])), 0.8)


static func molotov_throw(r: RandomNumberGenerator) -> PackedFloat32Array:
	var whoosh := Synth.bandpass(Synth.noise(0.3, 0, 0.1, 5.0, 0.6, r), 400.0, 2500.0)
	var slosh := Synth.lowpass(Synth.noise(0.15, 2, 0.01, 12.0, 0.5, r), 600.0)
	return Synth.normalize(Synth.fade_edges(Synth.combine([whoosh, slosh] as Array[PackedFloat32Array])), 0.6)


## Molotov caindo: vidro quebrando + "WHOOMP" do fogo.
static func molotov_burst(r: RandomNumberGenerator) -> PackedFloat32Array:
	var glass := Synth.highpass(Synth.noise(0.2, 0, 0.0005, 18.0, 0.7, r), 3500.0)
	for i: int in 6:
		Synth.mix_into(glass, Synth.tone(r.randf_range(3000, 6000), 0.08, Synth.Wave.SINE, 0.001, 40.0, 0.25),
				r.randf_range(0.0, 0.12))
	var whoomp := Synth.lowpass(Synth.noise(0.6, 1, 0.03, 4.5, 1.0, r), 900.0)
	var low := Synth.tone(70.0, 0.4, Synth.Wave.SINE, 0.02, 6.0, 0.7, 45.0)
	var out := Synth.combine([glass, whoomp, low] as Array[PackedFloat32Array])
	return Synth.normalize(Synth.fade_edges(out), 0.9)


## Fogo continuo (loop): crepitar discreto.
static func fire_loop(r: RandomNumberGenerator) -> PackedFloat32Array:
	var out := Synth.lowpass(Synth.noise(2.0, 1, 0.0, 0.0, 0.25, r), 700.0)
	for i: int in 26:
		Synth.mix_wrap(out, Synth.highpass(Synth.noise(0.03, 0, 0.0005, 80.0, r.randf_range(0.3, 0.7), r), 2500.0),
				r.randi_range(0, out.size() - 1))
	return Synth.normalize(out, 0.5)


## Gas: chiado de vazamento (loop).
static func gas_loop(r: RandomNumberGenerator) -> PackedFloat32Array:
	var out := Synth.bandpass(Synth.noise(2.0, 0, 0.0, 0.0, 0.5, r), 2500.0, 8000.0)
	Synth.tremolo(out, 0.5, 0.35)
	return Synth.normalize(out, 0.4)


static func gas_start(r: RandomNumberGenerator) -> PackedFloat32Array:
	var psst := Synth.bandpass(Synth.noise(0.5, 0, 0.01, 4.0, 0.9, r), 1800.0, 7000.0)
	var click := Synth.tone(900.0, 0.03, Synth.Wave.SQUARE, 0.001, 80.0, 0.3)
	return Synth.normalize(Synth.combine([click, psst] as Array[PackedFloat32Array]), 0.7)


# --- Impactos e combate ----------------------------------------------------------

## Bala acertando carne: "thud" curto.
static func impact(r: RandomNumberGenerator) -> PackedFloat32Array:
	var thud := Synth.lowpass(Synth.noise(0.08, 1, 0.0005, 40.0, 0.9, r), r.randf_range(700, 1100))
	var body := Synth.tone(r.randf_range(110, 140), 0.07, Synth.Wave.SINE, 0.001, 45.0, 0.6)
	return Synth.normalize(Synth.fade_edges(Synth.combine([thud, body] as Array[PackedFloat32Array])), 0.6)


## Critico: impacto + "ting" metalico brilhante.
static func crit(r: RandomNumberGenerator) -> PackedFloat32Array:
	var hit := impact(r)
	var ting := Synth.tone(r.randf_range(1900, 2200), 0.25, Synth.Wave.SINE, 0.001, 14.0, 0.5)
	Synth.mix_into(ting, Synth.tone(3100, 0.18, Synth.Wave.SINE, 0.001, 18.0, 0.25), 0.0)
	return Synth.normalize(Synth.combine([hit, ting] as Array[PackedFloat32Array]), 0.8)


## Explosao: grave, estilhacos e cauda com eco.
static func explosion(r: RandomNumberGenerator) -> PackedFloat32Array:
	var boom := Synth.drive(Synth.lowpass(Synth.noise(1.2, 2, 0.002, 3.2, 1.0, r), 500.0), 1.8)
	var sub := Synth.tone(r.randf_range(48, 58), 0.9, Synth.Wave.SINE, 0.003, 4.0, 1.0, 28.0)
	var debris := Synth.highpass(Synth.noise(0.5, 0, 0.05, 7.0, 0.3, r), 2500.0)
	var out := Synth.combine([boom, sub] as Array[PackedFloat32Array])
	Synth.mix_into(out, debris, 0.08)
	return Synth.normalize(Synth.fade_edges(Synth.echo(out, 0.14, 0.35, 0.6, 0.3), 0.001, 0.2), 1.0)


# --- Zumbis ---------------------------------------------------------------------

## Gemido: serrote com vibrato lento, filtrado como "voz".
static func groan(r: RandomNumberGenerator, base: float, length: float, rough: float) -> PackedFloat32Array:
	var f := base * r.randf_range(0.85, 1.15)
	var v := Synth.tone(f, length, Synth.Wave.SAW, 0.12, 1.2, 0.7, f * r.randf_range(0.7, 0.9),
			r.randf_range(4.0, 7.0), 0.04)
	Synth.bandpass(v, 250.0, 1400.0)
	var breath := Synth.bandpass(Synth.noise(length, 0, 0.1, 1.5, rough, r), 600.0, 2500.0)
	var out := Synth.combine([v, breath] as Array[PackedFloat32Array])
	return Synth.normalize(Synth.fade_edges(Synth.drive(out, 1.5), 0.02, 0.15), 0.7)


static func zombie_groan(r: RandomNumberGenerator) -> PackedFloat32Array:
	return groan(r, 120.0, r.randf_range(0.7, 1.1), 0.3)


## Corredor: grito agudo e agressivo.
static func runner_screech(r: RandomNumberGenerator) -> PackedFloat32Array:
	var f := r.randf_range(380, 460)
	var v := Synth.tone(f, 0.55, Synth.Wave.SAW, 0.02, 3.0, 0.8, f * 1.4, 11.0, 0.05)
	Synth.bandpass(v, 700.0, 3500.0)
	var rasp := Synth.bandpass(Synth.noise(0.55, 0, 0.02, 3.0, 0.5, r), 1500.0, 5000.0)
	return Synth.normalize(Synth.fade_edges(Synth.drive(Synth.combine([v, rasp] as Array[PackedFloat32Array]), 2.0)), 0.75)


## Brutamontes: rosnado grave.
static func brute_growl(r: RandomNumberGenerator) -> PackedFloat32Array:
	var v := groan(r, 62.0, r.randf_range(0.9, 1.3), 0.5)
	var sub := Synth.tone(45.0, v.size() / float(Synth.RATE), Synth.Wave.SINE, 0.1, 1.5, 0.5)
	return Synth.normalize(Synth.combine([v, sub] as Array[PackedFloat32Array]), 0.85)


## Inchado: gorgolejo borbulhante (assinatura propria).
static func bloater_gurgle(r: RandomNumberGenerator) -> PackedFloat32Array:
	var out := Synth.silence(0.9)
	for i: int in 9:
		var bubble := Synth.tone(r.randf_range(180, 420), 0.08, Synth.Wave.SINE, 0.005, 25.0, 0.6,
				r.randf_range(500, 900))
		Synth.mix_into(out, bubble, r.randf_range(0.0, 0.8))
	Synth.mix_into(out, Synth.lowpass(Synth.noise(0.9, 2, 0.1, 2.0, 0.4, r), 400.0), 0.0)
	return Synth.normalize(Synth.fade_edges(out), 0.7)


## Inchado prestes a explodir: bipes acelerando + chiado subindo (1 s).
static func bloater_fuse(_r: RandomNumberGenerator) -> PackedFloat32Array:
	var out := Synth.silence(1.0)
	var t := 0.0
	var gap := 0.22
	var f := 1200.0
	while t < 0.95:
		Synth.mix_into(out, Synth.tone(f, 0.05, Synth.Wave.SQUARE, 0.001, 30.0, 0.45), t)
		t += gap
		gap = maxf(0.05, gap * 0.72)
		f += 120.0
	var hiss := Synth.tone(300.0, 1.0, Synth.Wave.SAW, 0.5, 0.0, 0.15, 1400.0)
	Synth.bandpass(hiss, 400.0, 3000.0)
	Synth.mix_into(out, hiss, 0.0)
	return Synth.normalize(out, 0.8)


static func zombie_hit(r: RandomNumberGenerator) -> PackedFloat32Array:
	var grunt := groan(r, 150.0, 0.2, 0.4)
	return Synth.normalize(Synth.combine([impact(r), grunt] as Array[PackedFloat32Array]), 0.7)


## Morte de zumbi: "splat" molhado + ultimo gemido.
static func zombie_death(r: RandomNumberGenerator) -> PackedFloat32Array:
	var splat := Synth.lowpass(Synth.noise(0.25, 1, 0.001, 14.0, 0.9, r), 1300.0)
	var moan := groan(r, 110.0, 0.4, 0.3)
	for i: int in moan.size():
		moan[i] *= 0.5
	return Synth.normalize(Synth.fade_edges(Synth.combine([splat, moan] as Array[PackedFloat32Array])), 0.65)


## Elite (dourado): sino brilhante "algo especial apareceu".
static func elite_appear(_r: RandomNumberGenerator) -> PackedFloat32Array:
	var out := Synth.silence(1.0)
	for k: int in 2:
		var f := 880.0 * (1.5 if k == 1 else 1.0)
		Synth.mix_into(out, Synth.tone(f, 0.8, Synth.Wave.SINE, 0.002, 4.0, 0.5), k * 0.14)
		Synth.mix_into(out, Synth.tone(f * 2.76, 0.5, Synth.Wave.SINE, 0.002, 7.0, 0.2), k * 0.14)
	return Synth.normalize(Synth.echo(out, 0.12, 0.4, 0.5), 0.75)


static func elite_death(r: RandomNumberGenerator) -> PackedFloat32Array:
	var out := zombie_death(r)
	Synth.mix_into(out, elite_appear(r), 0.05, 0.6)
	return Synth.normalize(out, 0.85)


# --- Chefes ---------------------------------------------------------------------

## Rugido: Colosso (grave, lento) e Mutante (mais agudo, metalico).
static func boss_roar(r: RandomNumberGenerator, mutant: bool) -> PackedFloat32Array:
	var base := 75.0 if not mutant else 140.0
	var v := groan(r, base, 1.6, 0.8)
	var sub := Synth.tone(base * 0.5, 1.6, Synth.Wave.SAW, 0.2, 1.0, 0.6, base * 0.4, 3.0, 0.03)
	Synth.lowpass(sub, 400.0)
	var out := Synth.combine([v, sub] as Array[PackedFloat32Array])
	if mutant:
		var metal := Synth.tone(base * 7.3, 1.2, Synth.Wave.SQUARE, 0.3, 1.5, 0.15, base * 5.0, 13.0, 0.03)
		Synth.bandpass(metal, 900.0, 3000.0)
		Synth.mix_into(out, metal, 0.1)
	return Synth.normalize(Synth.echo(Synth.drive(out, 2.2), 0.18, 0.3, 0.5, 0.3), 0.95)


## Investida do chefe: rosnado curto + passos pesados.
static func boss_charge(r: RandomNumberGenerator) -> PackedFloat32Array:
	var out := groan(r, 70.0, 0.5, 0.6)
	for i: int in 4:
		Synth.mix_into(out, Synth.tone(55.0, 0.15, Synth.Wave.SINE, 0.001, 20.0, 0.8, 35.0), 0.3 + i * 0.12)
	return Synth.normalize(Synth.drive(out, 1.6), 0.9)


static func boss_death(r: RandomNumberGenerator) -> PackedFloat32Array:
	var roar := boss_roar(r, false)
	var fall := Synth.tone(60.0, 1.2, Synth.Wave.SINE, 0.01, 2.5, 1.0, 25.0)
	var out := Synth.combine([roar, fall] as Array[PackedFloat32Array])
	Synth.mix_into(out, explosion(r), 0.6, 0.6)
	return Synth.normalize(out, 1.0)


# --- Jogador ----------------------------------------------------------------------

static func player_hurt(r: RandomNumberGenerator) -> PackedFloat32Array:
	var punch := Synth.lowpass(Synth.noise(0.15, 1, 0.0005, 20.0, 1.0, r), 900.0)
	var grunt := Synth.tone(r.randf_range(160, 190), 0.18, Synth.Wave.SAW, 0.005, 12.0, 0.5, 120.0)
	Synth.bandpass(grunt, 200.0, 1500.0)
	return Synth.normalize(Synth.combine([punch, grunt] as Array[PackedFloat32Array]), 0.85)


## Coracao batendo (vida baixa).
static func heartbeat(_r: RandomNumberGenerator) -> PackedFloat32Array:
	var out := Synth.silence(1.0)
	Synth.mix_into(out, Synth.tone(55.0, 0.15, Synth.Wave.SINE, 0.005, 20.0, 1.0, 40.0), 0.0)
	Synth.mix_into(out, Synth.tone(50.0, 0.15, Synth.Wave.SINE, 0.005, 22.0, 0.7, 38.0), 0.22)
	return Synth.normalize(out, 0.8)


static func heal(_r: RandomNumberGenerator) -> PackedFloat32Array:
	var out := Synth.silence(0.6)
	for i: int in 4:
		Synth.mix_into(out, Synth.tone(Synth.midi(72 + i * 4), 0.35, Synth.Wave.SINE, 0.01, 6.0, 0.4), i * 0.07)
	return Synth.normalize(out, 0.6)


# --- Coleta, progressao e recompensas -----------------------------------------------

## XP: "plim" curto; o Audio sobe o tom quando voce coleta varias em sequencia.
static func xp(_r: RandomNumberGenerator) -> PackedFloat32Array:
	var a := Synth.tone(1320.0, 0.09, Synth.Wave.SINE, 0.001, 30.0, 0.5)
	Synth.mix_into(a, Synth.tone(1980.0, 0.07, Synth.Wave.SINE, 0.001, 40.0, 0.25), 0.0)
	return Synth.normalize(a, 0.5)


static func coin(r: RandomNumberGenerator) -> PackedFloat32Array:
	var f := r.randf_range(1900, 2100)
	var out := Synth.tone(f, 0.12, Synth.Wave.SQUARE, 0.001, 25.0, 0.3)
	Synth.mix_into(out, Synth.tone(f * 1.5, 0.2, Synth.Wave.SQUARE, 0.001, 15.0, 0.3), 0.06)
	return Synth.normalize(Synth.lowpass(out, 6000.0), 0.55)


static func chest(_r: RandomNumberGenerator) -> PackedFloat32Array:
	var out := Synth.silence(1.2)
	Synth.mix_into(out, Synth.tone(90.0, 0.2, Synth.Wave.SQUARE, 0.001, 20.0, 0.4, 60.0), 0.0)  # tranca
	for i: int in 6:
		Synth.mix_into(out, Synth.tone(Synth.midi(76 + [0, 4, 7, 12, 16, 19][i]), 0.4, Synth.Wave.TRIANGLE,
				0.002, 6.0, 0.35), 0.15 + i * 0.06)
	return Synth.normalize(Synth.echo(out, 0.1, 0.3, 0.4), 0.8)


## Level up: arpejo ascendente brilhante.
static func level_up(_r: RandomNumberGenerator) -> PackedFloat32Array:
	var out := Synth.silence(1.0)
	var notes := [60, 64, 67, 72, 76, 79]
	for i: int in notes.size():
		Synth.mix_into(out, Synth.tone(Synth.midi(notes[i]), 0.5, Synth.Wave.TRIANGLE, 0.003, 5.0, 0.4), i * 0.055)
		Synth.mix_into(out, Synth.tone(Synth.midi(notes[i] + 12), 0.3, Synth.Wave.SINE, 0.003, 8.0, 0.15), i * 0.055)
	return Synth.normalize(Synth.echo(out, 0.11, 0.35, 0.5), 0.8)


static func evolve(r: RandomNumberGenerator) -> PackedFloat32Array:
	var rise := Synth.tone(200.0, 0.8, Synth.Wave.SAW, 0.6, 0.5, 0.4, 900.0)
	Synth.lowpass(rise, 2500.0)
	var out := Synth.silence(2.0)
	Synth.mix_into(out, rise, 0.0)
	Synth.mix_into(out, explosion(r), 0.75, 0.5)
	for i: int in 4:
		Synth.mix_into(out, Synth.tone(Synth.midi([67, 71, 74, 79][i]), 1.0, Synth.Wave.SAW, 0.01, 2.5, 0.25), 0.8)
	Synth.lowpass(out, 5000.0)
	return Synth.normalize(Synth.echo(out, 0.15, 0.35, 0.5), 0.95)


## Fanfarra curta (desbloqueios). `tier`: 0 conquista, 1 mapa, 2 personagem, 3 recorde.
static func fanfare(_r: RandomNumberGenerator, tier: int) -> PackedFloat32Array:
	var out := Synth.silence(1.8)
	var roots := [72, 67, 64, 69]
	var root: int = roots[clampi(tier, 0, 3)]
	var seq := [0, 4, 7, 12] if tier != 3 else [0, 7, 12, 16, 19]
	for i: int in seq.size():
		var n := Synth.tone(Synth.midi(root + seq[i]), 0.9 if i == seq.size() - 1 else 0.3, Synth.Wave.SAW,
				0.01, 3.0, 0.3)
		Synth.lowpass(n, 3500.0)
		Synth.mix_into(out, n, i * 0.12)
	Synth.mix_into(out, Synth.tone(Synth.midi(root - 12), 1.2, Synth.Wave.SINE, 0.02, 2.0, 0.4), 0.0)
	return Synth.normalize(Synth.echo(out, 0.13, 0.35, 0.5), 0.85)


## Raridade da carta escolhida: 0 comum ... 3 lendaria (camadas a mais).
static func card_pick(_r: RandomNumberGenerator, rarity: int) -> PackedFloat32Array:
	var out := Synth.tone(Synth.midi(76), 0.25, Synth.Wave.TRIANGLE, 0.002, 10.0, 0.5)
	Synth.mix_into(out, Synth.tone(Synth.midi(83), 0.3, Synth.Wave.TRIANGLE, 0.002, 9.0, 0.4), 0.06)
	if rarity >= 1:
		Synth.mix_into(out, Synth.tone(Synth.midi(88), 0.5, Synth.Wave.SINE, 0.002, 6.0, 0.35), 0.12)
	if rarity >= 2:
		for i: int in 5:
			Synth.mix_into(out, Synth.tone(Synth.midi(91 + i * 2), 0.3, Synth.Wave.SINE, 0.001, 10.0, 0.15), 0.15 + i * 0.03)
	if rarity >= 3:
		var choir := Synth.tone(Synth.midi(64), 1.2, Synth.Wave.SAW, 0.1, 1.8, 0.3, -1.0, 5.0, 0.01)
		Synth.lowpass(choir, 2000.0)
		Synth.mix_into(out, choir, 0.05)
	return Synth.normalize(Synth.echo(out, 0.12, 0.3, 0.5), 0.8)


# --- Interface ----------------------------------------------------------------------

static func ui_click(r: RandomNumberGenerator) -> PackedFloat32Array:
	var out := Synth.tone(r.randf_range(1050, 1150), 0.04, Synth.Wave.SQUARE, 0.0005, 70.0, 0.25)
	Synth.mix_into(out, Synth.highpass(Synth.noise(0.02, 0, 0.0005, 120.0, 0.2, r), 3000.0), 0.0)
	return Synth.normalize(Synth.lowpass(out, 5000.0), 0.45)


static func ui_select(_r: RandomNumberGenerator) -> PackedFloat32Array:
	var out := Synth.tone(Synth.midi(79), 0.12, Synth.Wave.TRIANGLE, 0.001, 18.0, 0.4)
	Synth.mix_into(out, Synth.tone(Synth.midi(84), 0.15, Synth.Wave.TRIANGLE, 0.001, 16.0, 0.35), 0.05)
	return Synth.normalize(out, 0.5)


static func ui_back(_r: RandomNumberGenerator) -> PackedFloat32Array:
	var out := Synth.tone(Synth.midi(76), 0.1, Synth.Wave.TRIANGLE, 0.001, 20.0, 0.4)
	Synth.mix_into(out, Synth.tone(Synth.midi(69), 0.15, Synth.Wave.TRIANGLE, 0.001, 16.0, 0.35), 0.05)
	return Synth.normalize(out, 0.45)


## Transicao (whoosh): troca de tela, abrir cartas.
static func whoosh(r: RandomNumberGenerator) -> PackedFloat32Array:
	var n := Synth.bandpass(Synth.noise(0.45, 0, 0.2, 3.0, 0.7, r), 400.0, 3500.0)
	var tone := Synth.tone(300.0, 0.45, Synth.Wave.SINE, 0.3, 2.0, 0.2, 700.0)
	return Synth.normalize(Synth.fade_edges(Synth.combine([n, tone] as Array[PackedFloat32Array]), 0.01, 0.1), 0.55)


static func pause_on(_r: RandomNumberGenerator) -> PackedFloat32Array:
	return Synth.normalize(Synth.tone(Synth.midi(67), 0.25, Synth.Wave.SINE, 0.005, 8.0, 0.5, Synth.midi(60)), 0.5)


static func pause_off(_r: RandomNumberGenerator) -> PackedFloat32Array:
	return Synth.normalize(Synth.tone(Synth.midi(60), 0.25, Synth.Wave.SINE, 0.005, 8.0, 0.5, Synth.midi(67)), 0.5)


# --- Alertas e eventos -------------------------------------------------------------

## Buzina grave pulsante: horda/evento chegando.
static func alarm_horn(_r: RandomNumberGenerator) -> PackedFloat32Array:
	var out := Synth.tone(110.0, 1.4, Synth.Wave.SAW, 0.05, 0.8, 0.6)
	Synth.mix_into(out, Synth.tone(164.8, 1.4, Synth.Wave.SAW, 0.05, 0.8, 0.4), 0.0)
	Synth.lowpass(out, 1200.0)
	Synth.tremolo(out, 5.0, 0.5)
	return Synth.normalize(Synth.fade_edges(out, 0.02, 0.2), 0.8)


## Sirene distante (ambiente).
static func siren(_r: RandomNumberGenerator) -> PackedFloat32Array:
	var out := Synth.tone(650.0, 3.5, Synth.Wave.TRIANGLE, 0.6, 0.5, 0.4, 650.0, 0.45, 0.25)
	Synth.lowpass(out, 1500.0)
	return Synth.normalize(Synth.fade_edges(Synth.echo(out, 0.25, 0.4, 0.6), 0.5, 1.0), 0.5)


## Queda de suprimentos: helicoptero/caixa caindo + paraquedas.
static func supply_drop(r: RandomNumberGenerator) -> PackedFloat32Array:
	var rotor := Synth.lowpass(Synth.noise(2.0, 1, 0.3, 0.6, 0.7, r), 500.0)
	Synth.tremolo(rotor, 18.0, 0.8)
	var land := Synth.tone(70.0, 0.4, Synth.Wave.SINE, 0.001, 10.0, 0.9, 40.0)
	Synth.mix_into(rotor, land, 1.6)
	return Synth.normalize(Synth.fade_edges(rotor, 0.2, 0.1), 0.7)


## Area contaminada: chiado toxico + borbulhas graves.
static func toxic(r: RandomNumberGenerator) -> PackedFloat32Array:
	var out := gas_start(r)
	Synth.mix_into(out, bloater_gurgle(r), 0.1, 0.6)
	return Synth.normalize(out, 0.7)


# --- Ambiente (loops longos e discretos) -------------------------------------------

## Cidade: ronco urbano grave + vento.
static func amb_city(r: RandomNumberGenerator) -> PackedFloat32Array:
	var rumble := Synth.lowpass(Synth.noise(6.0, 2, 0.0, 0.0, 0.6, r), 220.0)
	var wind := Synth.bandpass(Synth.noise(6.0, 1, 0.0, 0.0, 0.35, r), 300.0, 1200.0)
	Synth.tremolo(wind, 0.17, 0.6)
	return Synth.normalize(_loopable(Synth.combine([rumble, wind] as Array[PackedFloat32Array])), 0.5)


## Orla: ondas quebrando em ciclos + vento maritimo.
static func amb_beach(r: RandomNumberGenerator) -> PackedFloat32Array:
	var n := Synth.lowpass(Synth.noise(8.0, 1, 0.0, 0.0, 0.8, r), 1600.0)
	for i: int in n.size():
		var t := float(i) / Synth.RATE
		var swell := pow(0.5 + 0.5 * sin(TAU * t / 4.0 - PI * 0.5), 2.2)
		n[i] *= 0.15 + swell
	var wind := Synth.bandpass(Synth.noise(8.0, 1, 0.0, 0.0, 0.25, r), 400.0, 1500.0)
	return Synth.normalize(_loopable(Synth.combine([n, wind] as Array[PackedFloat32Array])), 0.55)


## Morro: vento mais forte e aberto + zumbido de gerador.
static func amb_hills(r: RandomNumberGenerator) -> PackedFloat32Array:
	var wind := Synth.bandpass(Synth.noise(6.0, 1, 0.0, 0.0, 0.7, r), 500.0, 2400.0)
	Synth.tremolo(wind, 0.23, 0.7)
	var hum := Synth.tone(60.0, 6.0, Synth.Wave.SAW, 0.0, 0.0, 0.08)
	Synth.lowpass(hum, 300.0)
	return Synth.normalize(_loopable(Synth.combine([wind, hum] as Array[PackedFloat32Array])), 0.5)


## Murmurio da horda (loop): muitas vozes graves sobrepostas.
static func horde_loop(r: RandomNumberGenerator) -> PackedFloat32Array:
	var out := Synth.silence(4.0)
	for i: int in 10:
		Synth.mix_wrap(out, groan(r, r.randf_range(80, 160), r.randf_range(0.8, 1.4), 0.4),
				r.randi_range(0, out.size() - 1), 0.4)
	Synth.lowpass(out, 1500.0)
	return Synth.normalize(_loopable(out), 0.5)


static func gull(r: RandomNumberGenerator) -> PackedFloat32Array:
	var out := Synth.silence(0.8)
	for i: int in 2:
		var g := Synth.tone(r.randf_range(1500, 1800), 0.25, Synth.Wave.SAW, 0.02, 6.0, 0.4, 1100.0, 9.0, 0.03)
		Synth.bandpass(g, 900.0, 3500.0)
		Synth.mix_into(out, g, i * 0.3)
	return Synth.normalize(out, 0.4)


static func metal_clank(r: RandomNumberGenerator) -> PackedFloat32Array:
	var out := Synth.silence(0.8)
	for f: float in [r.randf_range(300, 400), r.randf_range(700, 900), r.randf_range(1500, 1900)]:
		Synth.mix_into(out, Synth.tone(f, 0.7, Synth.Wave.SINE, 0.001, 6.0, 0.3), 0.0)
	Synth.mix_into(out, Synth.noise(0.05, 0, 0.0005, 60.0, 0.5, r), 0.0)
	return Synth.normalize(Synth.echo(out, 0.2, 0.3, 0.5), 0.45)


static func dog_bark(r: RandomNumberGenerator) -> PackedFloat32Array:
	var out := Synth.silence(0.9)
	for i: int in 2:
		var b := Synth.tone(r.randf_range(330, 420), 0.12, Synth.Wave.SAW, 0.005, 18.0, 0.6, 220.0)
		Synth.bandpass(b, 300.0, 2500.0)
		Synth.mix_into(out, b, i * 0.28)
	return Synth.normalize(Synth.echo(out, 0.3, 0.3, 0.5), 0.4)


## Sino distante (assinatura do Cristo, la no alto do morro).
static func bell(_r: RandomNumberGenerator) -> PackedFloat32Array:
	var out := Synth.silence(3.0)
	for p: Array in [[1.0, 0.6], [2.4, 0.3], [3.0, 0.2], [4.2, 0.1]]:
		Synth.mix_into(out, Synth.tone(220.0 * float(p[0]), 3.0, Synth.Wave.SINE, 0.002, 1.2, float(p[1])), 0.0)
	return Synth.normalize(Synth.echo(out, 0.35, 0.4, 0.5), 0.4)


## Cabo do bondinho rangendo (assinatura do Pao de Acucar).
static func creak(r: RandomNumberGenerator) -> PackedFloat32Array:
	var c := Synth.tone(r.randf_range(180, 240), 1.2, Synth.Wave.SAW, 0.2, 1.5, 0.4, 260.0, 23.0, 0.08)
	Synth.bandpass(c, 300.0, 2000.0)
	return Synth.normalize(Synth.fade_edges(c, 0.1, 0.3), 0.35)


## Faz o loop "fechar" sem estalo (mistura o fim no comeco).
static func _loopable(a: PackedFloat32Array) -> PackedFloat32Array:
	var x := mini(a.size() / 4, Synth.samples(0.5))
	for i: int in x:
		var w := float(i) / x
		a[i] = a[i] * w + a[a.size() - x + i] * (1.0 - w)
	a.resize(a.size() - x)
	return a
