class_name ProjectileManager
extends Node3D
## Todos os projeteis do jogo (balas, chumbo, explosivos arremessados).
## Como os zumbis, sao so dados (sem nos) e desenhados em lote.
## Balas param ao bater em predios (grade do mapa).

const GROUP := &"projectile_manager"
const BULLET_HEIGHT := 1.0
const THROW_HEIGHT := 3.0

enum Kind { BULLET, THROWN }


class Proj:
	extends RefCounted
	var kind: int = 0
	var weapon: Weapon
	var pos: Vector2
	var dir: Vector2
	var speed: float
	var radius: float
	var pierce: int
	var life: float
	var hits: Array[int] = []
	var start: Vector2
	var target: Vector2
	var t: float
	var flight: float
	var visual: int
	var color: Color


var _active: Array[Proj] = []
var _free: Array[Proj] = []
var _renderers: Dictionary = {}  # WeaponData.Visual -> InstanceRenderer
var _candidates: Array[EnemyAgent] = []
var _enemies: EnemyManager
var _map: GameMap


func _enter_tree() -> void:
	add_to_group(GROUP)


func _ready() -> void:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	_add_renderer(WeaponData.Visual.BULLET, PlaceholderMeshes.bullet(), mat)
	_add_renderer(WeaponData.Visual.PELLET, PlaceholderMeshes.bullet(), mat)
	var lit := StandardMaterial3D.new()
	lit.vertex_color_use_as_albedo = true
	_add_renderer(WeaponData.Visual.BALL, PlaceholderMeshes.ball(), lit)


static func find(tree: SceneTree) -> ProjectileManager:
	return tree.get_first_node_in_group(GROUP) as ProjectileManager


func count() -> int:
	return _active.size()


func spawn_bullet(weapon: Weapon, from: Vector2, dir: Vector2) -> void:
	var p := _new_proj(weapon, Kind.BULLET)
	p.pos = from + dir * 0.5
	p.dir = dir
	p.speed = weapon.projectile_speed
	p.radius = weapon.final_area()
	p.pierce = weapon.pierce
	p.life = weapon.lifetime


func spawn_thrown(weapon: Weapon, from: Vector2, target: Vector2) -> void:
	var p := _new_proj(weapon, Kind.THROWN)
	p.start = from
	p.pos = from
	p.target = target
	p.t = 0.0
	p.flight = weapon.lifetime
	p.radius = weapon.final_area()


func _new_proj(weapon: Weapon, kind: int) -> Proj:
	var p: Proj = _free.pop_back() if not _free.is_empty() else Proj.new()
	p.kind = kind
	p.weapon = weapon
	p.hits.clear()
	p.visual = weapon.data.projectile_visual
	p.color = weapon.data.color
	_active.append(p)
	return p


func _physics_process(delta: float) -> void:
	if _enemies == null:
		_enemies = EnemyManager.find(get_tree())
		_map = GameMap.find(get_tree())
	for i: int in range(_active.size() - 1, -1, -1):
		var p := _active[i]
		var alive := _update_bullet(p, delta) if p.kind == Kind.BULLET else _update_thrown(p, delta)
		if not alive:
			_active[i] = _active[_active.size() - 1]
			_active.pop_back()
			p.weapon = null
			_free.append(p)


func _update_bullet(p: Proj, delta: float) -> bool:
	if not is_instance_valid(p.weapon) or _enemies == null:
		return false
	p.pos += p.dir * p.speed * delta
	p.life -= delta
	if p.life <= 0.0 or (_map and _map.grid.is_blocked(p.pos)):
		return false
	_enemies.grid.query_radius(p.pos, p.radius + EnemyManager.MAX_ENEMY_RADIUS, _candidates)
	for e: EnemyAgent in _candidates:
		if not e.alive or p.hits.has(e.uid):
			continue
		if e.pos.distance_to(p.pos) > p.radius + e.radius:
			continue
		p.hits.append(e.uid)
		p.weapon.hit(e, p.dir)
		p.pierce -= 1
		if p.pierce <= 0:
			return false
	return true


func _update_thrown(p: Proj, delta: float) -> bool:
	if not is_instance_valid(p.weapon) or _enemies == null:
		return false
	p.t += delta
	var u := clampf(p.t / p.flight, 0.0, 1.0)
	p.pos = p.start.lerp(p.target, u)
	if u < 1.0:
		return true
	# Explosao: dano em area.
	_enemies.grid.query_radius(p.pos, p.radius + EnemyManager.MAX_ENEMY_RADIUS, _candidates)
	for e: EnemyAgent in _candidates:
		if e.alive and e.pos.distance_to(p.pos) <= p.radius + e.radius:
			p.weapon.hit(e, (e.pos - p.pos).normalized())
	Events.explosion.emit(p.pos, p.radius)
	Events.camera_shake_requested.emit(2.5)
	Audio.play(&"explosion", -6.0)
	return false


func _process(_delta: float) -> void:
	for r: InstanceRenderer in _renderers.values():
		r.begin()
	for p: Proj in _active:
		var r: InstanceRenderer = _renderers[p.visual]
		if p.kind == Kind.BULLET:
			var scale := 0.7 if p.visual == WeaponData.Visual.PELLET else 1.0
			r.add(GroundPlane.to_3d(p.pos, BULLET_HEIGHT), GroundPlane.heading(p.dir), scale, p.color)
		else:
			var u := clampf(p.t / p.flight, 0.0, 1.0)
			var h := 0.8 + sin(u * PI) * THROW_HEIGHT
			r.add(GroundPlane.to_3d(p.pos, h), p.t * 12.0, 1.3, p.color)
	for r: InstanceRenderer in _renderers.values():
		r.finish()


func _add_renderer(visual: int, mesh: Mesh, mat: Material) -> void:
	var r := InstanceRenderer.new()
	r.name = "Render_%d" % visual
	r.setup(mesh, mat, 128)
	add_child(r)
	_renderers[visual] = r
