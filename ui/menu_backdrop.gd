class_name MenuBackdrop
extends Control
## Fundo dos menus desenhado por codigo (placeholder de arte):
## ceu de por do sol enfumacado, Pao de Acucar, Cristo no morro, silhueta de
## predios com janelas acesas, mar e o calcadao de ondas. Cinzas caem devagar.
## Para trocar por uma arte final: substitua por um TextureRect.

var _time: float = 0.0
var _ash: PackedVector2Array = PackedVector2Array()
var _rng := RandomNumberGenerator.new()
var _buildings: Array[Rect2] = []


func _ready() -> void:
	UiKit.full_rect(self)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rng.seed = 21
	for i: int in 60:
		_ash.append(Vector2(_rng.randf(), _rng.randf()))
	resized.connect(_layout)
	_layout()


func _layout() -> void:
	_buildings.clear()
	var x := -10.0
	var base := size.y * 0.74
	while x < size.x:
		var w := _rng.randf_range(34, 80)
		var h := _rng.randf_range(60, 210)
		_buildings.append(Rect2(x, base - h, w, h))
		x += w + _rng.randf_range(2, 10)


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y
	# Ceu em faixas (do topo escuro ao horizonte alaranjado).
	var bands := 24
	for i: int in bands:
		var t := float(i) / bands
		var c := Color(0.12, 0.08, 0.12).lerp(Color(0.95, 0.45, 0.18), pow(t, 1.6))
		draw_rect(Rect2(0, h * 0.62 * t, w, h * 0.62 / bands + 1), c)
	# Sol baixo e fumaca.
	draw_circle(Vector2(w * 0.72, h * 0.58), h * 0.11, Color(1.0, 0.75, 0.4, 0.9))
	for i: int in 5:
		var sx := fposmod(w * (0.15 + i * 0.22) + _time * 6.0, w + 200) - 100
		draw_circle(Vector2(sx, h * (0.25 + 0.05 * i)), h * 0.09, Color(0.15, 0.1, 0.12, 0.18))
	# Pao de Acucar (dois morros arredondados) e mar.
	_draw_hill(Vector2(w * 0.86, h * 0.64), h * 0.22, h * 0.09, Color(0.2, 0.14, 0.15))
	_draw_hill(Vector2(w * 0.77, h * 0.64), h * 0.11, h * 0.06, Color(0.22, 0.15, 0.16))
	# Corcovado com o Cristo.
	_draw_hill(Vector2(w * 0.2, h * 0.62), h * 0.3, h * 0.2, Color(0.16, 0.11, 0.13))
	var cx := w * 0.2
	var top := h * 0.62 - h * 0.3
	draw_rect(Rect2(cx - 4, top - 44, 8, 44), Color(0.12, 0.09, 0.1))
	draw_rect(Rect2(cx - 26, top - 36, 52, 7), Color(0.12, 0.09, 0.1))
	draw_circle(Vector2(cx, top - 49), 6, Color(0.12, 0.09, 0.1))
	draw_rect(Rect2(0, h * 0.62, w, h * 0.12), Color(0.12, 0.17, 0.22))
	# Predios com janelas acesas (algumas piscando).
	for i: int in _buildings.size():
		var b := _buildings[i]
		draw_rect(b, Color(0.07, 0.06, 0.07))
		var wy := b.position.y + 8
		while wy < b.end.y - 10:
			var wx := b.position.x + 6
			while wx < b.end.x - 8:
				var seed_v := sin(wx * 12.9898 + wy * 78.233) * 43758.5453
				var lit := fposmod(seed_v, 1.0)
				if lit > 0.82:
					var flicker := 0.6 + 0.4 * sin(_time * 3.0 + seed_v)
					draw_rect(Rect2(wx, wy, 5, 6), Color(1.0, 0.7, 0.35, 0.8 * flicker))
				wx += 11
			wy += 14
	# Calcadao de Copacabana (ondas pretas e brancas).
	var y0 := h * 0.74
	draw_rect(Rect2(0, y0, w, h - y0), Color(0.08, 0.07, 0.07))
	for k: int in 6:
		var pts := PackedVector2Array()
		for i: int in 65:
			var px := w * i / 64.0
			pts.append(Vector2(px, y0 + 18 + k * 20 + sin(px / 40.0 + k) * 6))
		draw_polyline(pts, Color(0.85, 0.82, 0.76, 0.18), 5.0)
	# Cinzas caindo.
	for i: int in _ash.size():
		var a := _ash[i]
		var p := Vector2(fposmod(a.x * w + sin(_time + i) * 20.0, w),
				fposmod(a.y * h + _time * (12.0 + i % 7), h))
		draw_circle(p, 1.6 + (i % 3), Color(0.8, 0.75, 0.7, 0.35))
	# Vinheta.
	draw_rect(Rect2(0, 0, w, h), Color(0, 0, 0, 0.25))


func _draw_hill(center: Vector2, half_width: float, height: float, color: Color) -> void:
	var pts := PackedVector2Array()
	for i: int in 33:
		var t := float(i) / 32.0
		var x := center.x - half_width + t * half_width * 2.0
		pts.append(Vector2(x, center.y - sin(t * PI) * height))
	pts.append(Vector2(center.x + half_width, center.y))
	pts.append(Vector2(center.x - half_width, center.y))
	draw_colored_polygon(pts, color)
