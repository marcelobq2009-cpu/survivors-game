extends GutTest
## Testes da grade espacial (game/world/spatial_grid.gd).

var grid: SpatialGrid


func before_each() -> void:
	grid = SpatialGrid.new(2.0)


func _add(pos: Vector2) -> EnemyAgent:
	var a := EnemyAgent.new()
	a.pos = pos
	a.alive = true
	grid.insert(a)
	return a


func test_query_radius_finds_only_items_inside() -> void:
	var near := _add(Vector2(0.5, 0.5))
	var edge := _add(Vector2(5, 0))
	var far := _add(Vector2(30, 30))
	var result: Array[EnemyAgent] = []
	grid.query_radius(Vector2.ZERO, 5.0, result)
	assert_has(result, near)
	assert_has(result, edge)
	assert_does_not_have(result, far)


func test_query_radius_handles_negative_coords() -> void:
	var neg := _add(Vector2(-3.5, -3.5))
	var result: Array[EnemyAgent] = []
	grid.query_radius(Vector2(-3, -3), 1.0, result)
	assert_eq(result, [neg] as Array[EnemyAgent])


func test_find_nearest_picks_closest() -> void:
	_add(Vector2(15, 0))
	var closest := _add(Vector2(0, 4.5))
	_add(Vector2(-10, -10))
	assert_same(grid.find_nearest(Vector2.ZERO, 50.0), closest)


func test_find_nearest_respects_max_radius() -> void:
	_add(Vector2(25, 0))
	assert_null(grid.find_nearest(Vector2.ZERO, 10.0))


func test_find_nearest_across_cells_is_exact() -> void:
	var same_cell_far := _add(Vector2(1.9, 1.9))
	var next_cell_near := _add(Vector2(-0.2, 0))
	assert_same(grid.find_nearest(Vector2(0.05, 0), 20.0), next_cell_near)
	assert_ne(grid.find_nearest(Vector2(0.05, 0), 20.0), same_cell_far)


func test_find_nearest_ignores_dead() -> void:
	var dead := _add(Vector2(1, 0))
	dead.alive = false
	var alive := _add(Vector2(3, 0))
	assert_same(grid.find_nearest(Vector2.ZERO, 10.0), alive)


func test_clear_empties_grid() -> void:
	_add(Vector2.ZERO)
	grid.clear()
	assert_eq(grid.size(), 0)
	assert_null(grid.find_nearest(Vector2.ZERO, 5.0))
