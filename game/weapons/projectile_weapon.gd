class_name ProjectileWeapon
extends Weapon
## Atira no inimigo mais proximo. Varios projeteis saem em leque.

const PROJECTILE_SCENE: PackedScene = preload("res://game/weapons/projectile.tscn")
const SPREAD := deg_to_rad(12.0)
const LAYER_GROUP := &"projectile_layer"

var _layer: Node


func _ready() -> void:
	super()
	_layer = get_tree().get_first_node_in_group(LAYER_GROUP)
	if _layer == null:
		_layer = get_parent()


func attack() -> void:
	if enemies == null:
		return
	var origin := global_position
	var target := enemies.grid.find_nearest(origin, target_range)
	if target == null:
		return
	var base_angle := (target.global_position - origin).angle()
	for i: int in projectile_count:
		var offset := (i - (projectile_count - 1) * 0.5) * SPREAD
		var p := Pool.acquire(PROJECTILE_SCENE, _layer) as Projectile
		p.setup(self, origin, Vector2.from_angle(base_angle + offset))
	Audio.play(&"shoot", -10.0)
