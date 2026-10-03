extends SceneTree
## Gera o icone do jogo (assets/icon.png, 512x512): por do sol, Cristo no morro
## e uma mao de zumbi saindo do chao. Arte original, sem licenca externa.
## Rodar: scripts/godot.(ps1|sh) --headless -s res://scripts/dev/make_icon.gd

const SIZE := 512
const STONE := Color(0.92, 0.9, 0.85)
const HAND := Color(0.45, 0.85, 0.3)


func _init() -> void:
	var img := Image.create_empty(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	for y: int in SIZE:
		for x: int in SIZE:
			img.set_pixel(x, y, _pixel(float(x) / SIZE, float(y) / SIZE))
	img.save_png("res://assets/icon.png")
	print("icone gerado")
	quit()


func _pixel(u: float, v: float) -> Color:
	# Ceu: roxo escuro no topo -> laranja no horizonte, com o sol.
	var c := Color(0.12, 0.06, 0.12).lerp(Color(1.0, 0.45, 0.12), pow(v, 1.4))
	var d := Vector2(u - 0.5, v - 0.62).length()
	if d < 0.2:
		c = c.lerp(Color(1.0, 0.82, 0.45), 1.0 - d / 0.2 * 0.6)
	# Morro (Corcovado) em silhueta, com o Cristo no topo.
	var hill := 0.66 - 0.28 * exp(-pow((u - 0.5) / 0.22, 2.0))
	if v > hill:
		c = Color(0.08, 0.05, 0.07)
	var cx := absf(u - 0.5)
	if (v > 0.27 and v < 0.39 and cx < 0.012) or (v > 0.295 and v < 0.31 and cx < 0.075) \
			or Vector2(u - 0.5, v - 0.262).length() < 0.013:
		c = STONE
	# Mao de zumbi verde saindo de baixo.
	if v > 0.74 and absf(u - 0.5) < 0.09:
		c = HAND
	for i: int in 4:
		var fx := 0.43 + i * 0.047
		var top := 0.6 + absf(i - 1.5) * 0.035
		if absf(u - fx) < 0.018 and v > top and v < 0.76:
			c = HAND
	# Cantos arredondados.
	var q := Vector2(absf(u - 0.5), absf(v - 0.5)) - Vector2(0.38, 0.38)
	if Vector2(maxf(q.x, 0.0), maxf(q.y, 0.0)).length() > 0.12:
		c.a = 0.0
	return c
