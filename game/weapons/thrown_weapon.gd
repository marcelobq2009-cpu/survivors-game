class_name ThrownWeapon
extends Weapon
## Arremessa um explosivo num zumbi (aleatorio, perto do mais proximo).
## Explode ao cair causando dano em area (ProjectileManager.explode).


func attack() -> void:
	if enemies == null or projectiles == null:
		return
	var from := origin()
	var nearest := enemies.grid.find_nearest(from, target_range)
	if nearest == null:
		return
	for i: int in final_count():
		var jitter := Vector2(_rng.randf_range(-1, 1), _rng.randf_range(-1, 1)) * 2.0 * i
		projectiles.spawn_thrown(self, from, nearest.pos + jitter)
	Audio.play(data.sound_id)
