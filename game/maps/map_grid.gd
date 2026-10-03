class_name MapGrid
extends RefCounted
## Grade de obstaculos do mapa (celulas de `cell` metros).
## Os zumbis consultam para contornar predios/carros (custo O(1) por consulta),
## e o spawner para nao criar zumbis dentro de paredes ou fora do mapa.
##
## Uma celula so e bloqueada se o CENTRO dela estiver dentro do obstaculo.
## Com celulas de 0,5 m, a area bloqueada passa no maximo 0,25 m da parede —
## menos que o raio do jogador (0,35 m). Assim o jogador nunca fica "dentro"
## de uma celula bloqueada (isso criava um esconderijo onde zumbis e balas
## nao chegavam).

var cell: float
var bounds: Rect2
var _w: int
var _h: int
var _blocked: PackedByteArray


func _init(p_bounds: Rect2, p_cell: float = 0.5) -> void:
	bounds = p_bounds
	cell = p_cell
	_w = ceili(bounds.size.x / cell)
	_h = ceili(bounds.size.y / cell)
	_blocked = PackedByteArray()
	_blocked.resize(_w * _h)


## Marca como bloqueado um retangulo (centro, tamanho, rotacao em radianos).
## `margin` aumenta o retangulo (use pouco: 0 a 0,15).
func block_rect(center: Vector2, size: Vector2, rotation: float = 0.0, margin: float = 0.0) -> void:
	var half := size * 0.5 + Vector2(margin, margin)
	# Caixa envolvente do retangulo girado (para saber quais celulas testar).
	var c := absf(cos(rotation))
	var s := absf(sin(rotation))
	var ext := Vector2(half.x * c + half.y * s, half.x * s + half.y * c)
	var min_c := _cell_of(center - ext)
	var max_c := _cell_of(center + ext)
	for y: int in range(maxi(0, min_c.y), mini(_h - 1, max_c.y) + 1):
		for x: int in range(maxi(0, min_c.x), mini(_w - 1, max_c.x) + 1):
			# Centro da celula, levado para o espaco local do retangulo.
			var p := bounds.position + Vector2((x + 0.5) * cell, (y + 0.5) * cell) - center
			var local := p.rotated(rotation)
			if absf(local.x) <= half.x and absf(local.y) <= half.y:
				_blocked[y * _w + x] = 1


func is_blocked(p: Vector2) -> bool:
	var c := _cell_of(p)
	if c.x < 0 or c.y < 0 or c.x >= _w or c.y >= _h:
		return true  # Fora do mapa conta como parede.
	return _blocked[c.y * _w + c.x] == 1


func is_free(p: Vector2) -> bool:
	return not is_blocked(p)


## Ponto livre mais proximo (procura em espiral). Retorna `p` se ja estiver livre.
func nearest_free(p: Vector2, max_radius: float = 12.0) -> Vector2:
	if is_free(p):
		return p
	var r := cell
	while r <= max_radius:
		for i: int in 16:
			var q := p + Vector2.from_angle(TAU * i / 16.0) * r
			if is_free(q):
				return q
		r += cell
	return p


func _cell_of(p: Vector2) -> Vector2i:
	return Vector2i(floori((p.x - bounds.position.x) / cell), floori((p.y - bounds.position.y) / cell))
