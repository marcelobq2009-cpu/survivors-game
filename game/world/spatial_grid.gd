class_name SpatialGrid
extends RefCounted
## Grade espacial: divide o mundo em celulas para responder rapido
## "quem esta perto deste ponto?" sem testar todos os inimigos.
## E reconstruida a cada frame pelo EnemyManager (clear + insert).
##
## IMPORTANTE: usa `position` dos itens (mais barato que global_position).
## Os itens devem ser filhos de um no que esta na origem do mundo.

var cell_size: float
var _cells: Dictionary[Vector2i, Array] = {}
var _count: int = 0


func _init(p_cell_size: float = 64.0) -> void:
	cell_size = p_cell_size


func clear() -> void:
	_cells.clear()
	_count = 0


func size() -> int:
	return _count


func insert(item: Node2D) -> void:
	var c := cell_of(item.position)
	var cell: Variant = _cells.get(c)
	if cell == null:
		_cells[c] = [item]
	else:
		(cell as Array).append(item)
	_count += 1


func cell_of(pos: Vector2) -> Vector2i:
	return Vector2i(floori(pos.x / cell_size), floori(pos.y / cell_size))


## Preenche `result` com os itens a ate `radius` de `pos` (limpa antes).
## Reaproveitar o mesmo array evita alocar memoria todo frame.
func query_radius(pos: Vector2, radius: float, result: Array[Node2D]) -> void:
	result.clear()
	var r2 := radius * radius
	var min_c := cell_of(pos - Vector2(radius, radius))
	var max_c := cell_of(pos + Vector2(radius, radius))
	for cx: int in range(min_c.x, max_c.x + 1):
		for cy: int in range(min_c.y, max_c.y + 1):
			var cell: Variant = _cells.get(Vector2i(cx, cy))
			if cell == null:
				continue
			for item: Node2D in cell as Array:
				if item.position.distance_squared_to(pos) <= r2:
					result.append(item)


## Item mais proximo de `pos` dentro de `max_radius` (ou null).
## Procura em "aneis" de celulas crescentes e para cedo quando ja achou.
func find_nearest(pos: Vector2, max_radius: float) -> Node2D:
	var center := cell_of(pos)
	var max_ring := ceili(max_radius / cell_size)
	var best: Node2D = null
	var best_d2 := max_radius * max_radius
	for ring: int in range(max_ring + 1):
		# Celulas do anel `ring` estao a pelo menos (ring-1)*cell_size de pos.
		var ring_min := maxf(0.0, (ring - 1) * cell_size)
		if best != null and ring_min * ring_min > best_d2:
			break
		for cx: int in range(center.x - ring, center.x + ring + 1):
			for cy: int in range(center.y - ring, center.y + ring + 1):
				if maxi(absi(cx - center.x), absi(cy - center.y)) != ring:
					continue  # So a borda do anel.
				var cell: Variant = _cells.get(Vector2i(cx, cy))
				if cell == null:
					continue
				for item: Node2D in cell as Array:
					var d2 := item.position.distance_squared_to(pos)
					if d2 <= best_d2:
						best_d2 = d2
						best = item
	return best
