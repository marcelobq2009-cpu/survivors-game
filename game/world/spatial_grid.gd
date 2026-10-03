class_name SpatialGrid
extends RefCounted
## Grade espacial: divide o chao em celulas para responder rapido
## "quais zumbis estao perto deste ponto?" sem testar todos.
## Reconstruida a cada frame pelo EnemyManager (clear + insert).

var cell_size: float
var _cells: Dictionary[Vector2i, Array] = {}
var _count: int = 0


func _init(p_cell_size: float = 2.0) -> void:
	cell_size = p_cell_size


func clear() -> void:
	_cells.clear()
	_count = 0


func size() -> int:
	return _count


func insert(agent: EnemyAgent) -> void:
	var c := cell_of(agent.pos)
	var cell: Variant = _cells.get(c)
	if cell == null:
		_cells[c] = [agent]
	else:
		(cell as Array).append(agent)
	_count += 1


func cell_of(pos: Vector2) -> Vector2i:
	return Vector2i(floori(pos.x / cell_size), floori(pos.y / cell_size))


## Preenche `result` com os agentes a ate `radius` de `pos` (limpa antes).
## Reaproveitar o mesmo array evita alocar memoria todo frame.
func query_radius(pos: Vector2, radius: float, result: Array[EnemyAgent]) -> void:
	result.clear()
	var r2 := radius * radius
	var min_c := cell_of(pos - Vector2(radius, radius))
	var max_c := cell_of(pos + Vector2(radius, radius))
	for cx: int in range(min_c.x, max_c.x + 1):
		for cy: int in range(min_c.y, max_c.y + 1):
			var cell: Variant = _cells.get(Vector2i(cx, cy))
			if cell == null:
				continue
			for a: EnemyAgent in cell as Array:
				if a.pos.distance_squared_to(pos) <= r2:
					result.append(a)


## Agente mais proximo de `pos` dentro de `max_radius` (ou null).
## Procura em "aneis" de celulas crescentes e para cedo quando ja achou.
func find_nearest(pos: Vector2, max_radius: float) -> EnemyAgent:
	var center := cell_of(pos)
	var max_ring := ceili(max_radius / cell_size)
	var best: EnemyAgent = null
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
				for a: EnemyAgent in cell as Array:
					if not a.alive:
						continue
					var d2 := a.pos.distance_squared_to(pos)
					if d2 <= best_d2:
						best_d2 = d2
						best = a
	return best
