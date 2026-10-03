class_name ProjectileWeapon
extends Weapon
## Atira no zumbi mais proximo. Varios projeteis saem em leque.
## Pistola, espingarda e metralhadora = este comportamento com numeros diferentes.


func attack() -> void:
	if enemies == null or projectiles == null:
		return
	var from := origin()
	var target := enemies.grid.find_nearest(from, target_range)
	if target == null:
		return
	var base := (target.pos - from).angle()
	var count := final_count()
	var spread := deg_to_rad(spread_degrees)
	for i: int in count:
		var t := 0.0 if count == 1 else (float(i) / (count - 1) - 0.5)
		var angle := base + t * spread + _rng.randf_range(-0.03, 0.03)
		projectiles.spawn_bullet(self, from, Vector2.from_angle(angle))
	Audio.play(data.sound_id, -8.0)
