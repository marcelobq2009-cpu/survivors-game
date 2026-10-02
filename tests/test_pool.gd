extends GutTest
## Testes do object pooling (autoload/pool.gd).

var pool: ObjectPool
var scene: PackedScene
var parent: Node2D


func before_each() -> void:
	pool = ObjectPool.new()
	add_child_autofree(pool)
	parent = Node2D.new()
	add_child_autofree(parent)
	scene = PackedScene.new()
	var template := Node2D.new()
	scene.pack(template)
	template.free()


func test_acquire_creates_child_of_parent() -> void:
	var node := pool.acquire(scene, parent)
	assert_not_null(node)
	assert_eq(node.get_parent(), parent)
	assert_eq(pool.active_count(scene), 1)


func test_release_then_acquire_reuses_same_node() -> void:
	var first := pool.acquire(scene, parent)
	pool.release(first)
	assert_eq(pool.active_count(scene), 0)
	assert_false((first as Node2D).visible, "liberado fica escondido")
	var second := pool.acquire(scene, parent)
	assert_same(second, first, "deve reaproveitar")
	assert_true((second as Node2D).visible)
	assert_eq(second.process_mode, Node.PROCESS_MODE_INHERIT)


func test_double_release_is_ignored() -> void:
	var node := pool.acquire(scene, parent)
	pool.release(node)
	pool.release(node)
	var a := pool.acquire(scene, parent)
	var b := pool.acquire(scene, parent)
	assert_ne(a, b, "nao pode entregar o mesmo no duas vezes")


func test_freed_nodes_are_skipped() -> void:
	var node := pool.acquire(scene, parent)
	pool.release(node)
	node.free()
	var fresh := pool.acquire(scene, parent)
	assert_true(is_instance_valid(fresh))


func test_release_of_non_pooled_node_frees_it() -> void:
	var stray := Node2D.new()
	add_child(stray)
	pool.release(stray)
	await wait_physics_frames(1)
	assert_false(is_instance_valid(stray))
