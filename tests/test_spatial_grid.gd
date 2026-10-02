extends GutTest
## Testes da grade espacial (game/world/spatial_grid.gd).

var grid: SpatialGrid


func before_each() -> void:
	grid = SpatialGrid.new(64.0)


func _add(pos: Vector2) -> Node2D:
	var n := Node2D.new()
	n.position = pos
	add_child_autofree(n)
	grid.insert(n)
	return n


func test_query_radius_finds_only_items_inside() -> void:
	var near := _add(Vector2(10, 10))
	var edge := _add(Vector2(100, 0))
	var far := _add(Vector2(500, 500))
	var result: Array[Node2D] = []
	grid.query_radius(Vector2.ZERO, 100.0, result)
	assert_has(result, near)
	assert_has(result, edge)
	assert_does_not_have(result, far)


func test_query_radius_handles_negative_coords() -> void:
	var neg := _add(Vector2(-70, -70))
	var result: Array[Node2D] = []
	grid.query_radius(Vector2(-60, -60), 20.0, result)
	assert_eq(result, [neg] as Array[Node2D])


func test_find_nearest_picks_closest() -> void:
	_add(Vector2(300, 0))
	var closest := _add(Vector2(0, 90))
	_add(Vector2(-200, -200))
	assert_same(grid.find_nearest(Vector2.ZERO, 1000.0), closest)


func test_find_nearest_respects_max_radius() -> void:
	_add(Vector2(500, 0))
	assert_null(grid.find_nearest(Vector2.ZERO, 200.0))


func test_find_nearest_across_cells_is_exact() -> void:
	# Item em celula vizinha mas mais perto que um na mesma celula.
	var same_cell_far := _add(Vector2(60, 60))   # dist ~84.8
	var next_cell_near := _add(Vector2(-5, 0))   # dist 5, outra celula
	assert_same(grid.find_nearest(Vector2(1, 0), 500.0), next_cell_near)
	assert_ne(grid.find_nearest(Vector2(1, 0), 500.0), same_cell_far)


func test_clear_empties_grid() -> void:
	_add(Vector2.ZERO)
	grid.clear()
	assert_eq(grid.size(), 0)
	assert_null(grid.find_nearest(Vector2.ZERO, 100.0))
