class_name ObjectPool
extends Node
## Object pooling (autoload "Pool").
## Em vez de criar e destruir nos o tempo todo (caro no celular), guardamos os
## nos "mortos" escondidos e reaproveitamos depois.
##
## Uso:
##   var e := Pool.acquire(ENEMY_SCENE, parent) as Enemy
##   ...
##   Pool.release(e)
##
## Opcional no no reaproveitado: func on_acquire() e func on_release().

const META_KEY := &"pool_key"
const META_FREE := &"pool_free"

var _free: Dictionary[String, Array] = {}
var _active: Dictionary[String, int] = {}


## Pega um no do pool (ou cria um novo) e garante que ele e filho de `parent`.
func acquire(scene: PackedScene, parent: Node) -> Node:
	var key := _key_for(scene)
	var node: Node = _pop_valid(key)
	if node == null:
		node = scene.instantiate()
		node.set_meta(META_KEY, key)
		parent.add_child(node)
	else:
		if node.get_parent() != parent:
			node.reparent(parent, false)
		node.process_mode = Node.PROCESS_MODE_INHERIT
		if node is CanvasItem:
			(node as CanvasItem).show()
	node.set_meta(META_FREE, false)
	_active[key] = _active.get(key, 0) + 1
	if node.has_method(&"on_acquire"):
		node.call(&"on_acquire")
	return node


## Devolve o no ao pool: ele fica escondido e sem processar.
func release(node: Node) -> void:
	if not is_instance_valid(node):
		return
	if not node.has_meta(META_KEY):
		node.queue_free()  # Nao veio do pool.
		return
	if node.get_meta(META_FREE, false):
		return  # Ja devolvido; ignora devolucao dupla.
	var key: String = node.get_meta(META_KEY)
	node.set_meta(META_FREE, true)
	if node.has_method(&"on_release"):
		node.call(&"on_release")
	if node is CanvasItem:
		(node as CanvasItem).hide()
	node.process_mode = Node.PROCESS_MODE_DISABLED
	if not _free.has(key):
		_free[key] = []
	_free[key].append(node)
	_active[key] = maxi(0, _active.get(key, 0) - 1)


## Quantos nos desta cena estao em uso agora (usado no overlay de debug).
func active_count(scene: PackedScene) -> int:
	return _active.get(_key_for(scene), 0)


## Esquece tudo (chamado quando a partida termina e a cena e destruida).
func clear() -> void:
	_free.clear()
	_active.clear()


func _pop_valid(key: String) -> Node:
	var list: Array = _free.get(key, [])
	while not list.is_empty():
		var candidate: Variant = list.pop_back()
		if is_instance_valid(candidate):
			return candidate as Node
	return null


func _key_for(scene: PackedScene) -> String:
	if scene.resource_path.is_empty():
		return "scene_%d" % scene.get_instance_id()
	return scene.resource_path
