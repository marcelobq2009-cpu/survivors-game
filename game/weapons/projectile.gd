class_name Projectile
extends Node2D
## Projetil simples (vem do Pool). Anda reto, acerta inimigos pela SpatialGrid
## e some ao esgotar `pierce` ou o tempo de vida.

const KNOCKBACK := 120.0

var _enemies: EnemyManager
var _direction: Vector2
var _speed: float
var _damage: float
var _radius: float
var _pierce_left: int
var _life_left: float
var _hit_ids: Array[int] = []
var _candidates: Array[Node2D] = []

@onready var sprite: Sprite2D = $Sprite


func setup(weapon: Weapon, origin: Vector2, direction: Vector2) -> void:
	_enemies = weapon.enemies
	global_position = origin
	_direction = direction
	rotation = direction.angle()
	_speed = weapon.projectile_speed
	_damage = weapon.final_damage()
	_radius = weapon.final_area()
	_pierce_left = weapon.pierce
	_life_left = weapon.lifetime
	_hit_ids.clear()
	sprite.texture = weapon.data.texture
	sprite.modulate = weapon.data.color
	var tex_size := sprite.texture.get_size().x if sprite.texture else 64.0
	sprite.scale = Vector2.ONE * (_radius * 2.0 / tex_size)


func _physics_process(delta: float) -> void:
	global_position += _direction * _speed * delta
	_life_left -= delta
	if _life_left <= 0.0:
		Pool.release(self)
		return
	_enemies.grid.query_radius(global_position, _radius + EnemyManager.MAX_ENEMY_RADIUS, _candidates)
	for n: Node2D in _candidates:
		var e := n as Enemy
		if not e.alive or _hit_ids.has(e.get_instance_id()):
			continue
		if e.global_position.distance_to(global_position) > _radius + e.data.radius:
			continue
		_hit_ids.append(e.get_instance_id())
		e.take_damage(_damage, _direction * KNOCKBACK)
		_pierce_left -= 1
		if _pierce_left <= 0:
			Pool.release(self)
			return
