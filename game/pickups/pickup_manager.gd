class_name PickupManager
extends Node3D
## Gemas de XP, moedas de ouro e baus que caem dos zumbis.
## Ficam paradas ate o jogador chegar perto (ima = pickup_radius), entao voam
## ate ele. Desenhadas em lote. Com muitas gemas no chao, o valor novo e somado
## a uma gema existente (nao cria mais objetos).

const GROUP := &"pickup_manager"
const MAX_GEMS := 300
const COLLECT_DISTANCE := 0.6
const START_SPEED := 4.0
const ACCELERATION := 40.0

enum Kind { GEM, COIN, CHEST }


class Pickup:
	extends RefCounted
	var kind: int = 0
	var pos: Vector2
	var value: int = 1
	var attracted: bool = false
	var speed: float = 0.0
	var phase: float = 0.0


var _items: Array[Pickup] = []
var _free: Array[Pickup] = []
var _gem_count: int = 0
var _time: float = 0.0
var _rng := RandomNumberGenerator.new()
var _gems: InstanceRenderer
var _coins: InstanceRenderer
var _chests: InstanceRenderer


func _enter_tree() -> void:
	add_to_group(GROUP)


func _ready() -> void:
	_rng.randomize()
	var glow := StandardMaterial3D.new()
	glow.vertex_color_use_as_albedo = true
	glow.emission_enabled = true
	glow.emission = Color(0.3, 0.3, 0.3)
	_gems = _renderer("Gems", PlaceholderMeshes.gem(), glow)
	_coins = _renderer("Coins", PlaceholderMeshes.coin(), PlaceholderMeshes.vertex_color_material())
	_chests = _renderer("Chests", PlaceholderMeshes.chest(), PlaceholderMeshes.vertex_color_material())
	Events.enemy_killed.connect(_on_enemy_killed)


static func find(tree: SceneTree) -> PickupManager:
	return tree.get_first_node_in_group(GROUP) as PickupManager


func gem_count() -> int:
	return _gem_count


func spawn(kind: int, pos: Vector2, value: int) -> void:
	if kind == Kind.GEM and _gem_count >= MAX_GEMS:
		_merge_into_existing_gem(value)
		return
	var p: Pickup = _free.pop_back() if not _free.is_empty() else Pickup.new()
	p.kind = kind
	p.pos = pos + Vector2(_rng.randf_range(-0.3, 0.3), _rng.randf_range(-0.3, 0.3))
	p.value = value
	p.attracted = false
	p.speed = 0.0
	p.phase = _rng.randf() * TAU
	_items.append(p)
	if kind == Kind.GEM:
		_gem_count += 1


## Puxa todas as gemas e moedas para o jogador (ima total / debug).
func vacuum_all() -> void:
	for p: Pickup in _items:
		if p.kind != Kind.CHEST:
			p.attracted = true
			p.speed = START_SPEED * 2.0


func _on_enemy_killed(a: EnemyAgent) -> void:
	spawn(Kind.GEM, a.pos, a.xp)
	var gold_chance := a.data.gold_chance * (4.0 if a.elite else 1.0)
	if _rng.randf() < gold_chance:
		spawn(Kind.COIN, a.pos + Vector2(0.4, 0), a.data.gold_value * (3 if a.elite else 1))
	if a.data.is_boss or _rng.randf() < a.data.chest_chance or (a.elite and _rng.randf() < 0.2):
		spawn(Kind.CHEST, a.pos + Vector2(-0.5, 0.3), 25 if a.data.is_boss else 10)


func _merge_into_existing_gem(value: int) -> void:
	for attempt: int in 8:
		var p := _items[_rng.randi_range(0, _items.size() - 1)]
		if p.kind == Kind.GEM:
			p.value += value
			return


func _physics_process(delta: float) -> void:
	_time += delta
	var player := GameState.player_position
	var magnet := GameState.pickup_radius
	for i: int in range(_items.size() - 1, -1, -1):
		var p := _items[i]
		var to := player - p.pos
		var dist := to.length()
		if not p.attracted:
			var reach := COLLECT_DISTANCE + 0.4 if p.kind == Kind.CHEST else magnet
			if dist > reach:
				continue
			p.attracted = true
			p.speed = START_SPEED
		p.speed += ACCELERATION * delta
		if dist <= COLLECT_DISTANCE or dist <= p.speed * delta:
			_collect(p)
			_items[i] = _items[_items.size() - 1]
			_items.pop_back()
			_free.append(p)
			continue
		p.pos += to / dist * p.speed * delta


func _collect(p: Pickup) -> void:
	match p.kind:
		Kind.GEM:
			_gem_count -= 1
			Events.xp_collected.emit(p.value)
			Audio.play(&"pickup_xp", -14.0)
		Kind.COIN:
			Events.gold_collected.emit(maxi(1, roundi(p.value * GameState.gold_mult)))
			Audio.play(&"pickup_gold", -10.0)
		Kind.CHEST:
			Events.gold_collected.emit(maxi(1, roundi(p.value * GameState.gold_mult)))
			Events.chest_opened.emit()
			Audio.play(&"chest", -4.0)


func _process(_delta: float) -> void:
	_gems.begin()
	_coins.begin()
	_chests.begin()
	for p: Pickup in _items:
		var bob := 0.45 + sin(_time * 3.0 + p.phase) * 0.1
		match p.kind:
			Kind.GEM:
				_gems.add(GroundPlane.to_3d(p.pos, bob), _time * 2.0 + p.phase,
						1.0 if p.value < 5 else 1.4, _gem_color(p.value))
			Kind.COIN:
				_coins.add(GroundPlane.to_3d(p.pos, bob), _time * 4.0 + p.phase, 1.0, Color.WHITE)
			Kind.CHEST:
				_chests.add(GroundPlane.to_3d(p.pos, 0.0), p.phase, 1.0, Color.WHITE)
	_gems.finish()
	_coins.finish()
	_chests.finish()


func _gem_color(value: int) -> Color:
	if value >= 20:
		return Color(1.0, 0.3, 0.4)
	if value >= 5:
		return Color(0.35, 0.6, 1.0)
	return Color(0.3, 1.0, 0.5)


func _renderer(node_name: String, mesh: Mesh, mat: Material) -> InstanceRenderer:
	var r := InstanceRenderer.new()
	r.name = node_name
	r.setup(mesh, mat, 64)
	add_child(r)
	return r
