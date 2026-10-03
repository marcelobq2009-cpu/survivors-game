class_name MeleeWeapon
extends Weapon
## Golpe em arco na frente do jogador (facao). Mira no zumbi mais proximo;
## se nao houver, golpeia para onde o jogador esta andando.

const ARC := deg_to_rad(150.0)

var _targets: Array[EnemyAgent] = []


func attack() -> void:
	if enemies == null:
		return
	var from := origin()
	var reach := final_area()
	var target := enemies.grid.find_nearest(from, reach * 1.6)
	if target == null:
		return
	var dir := (target.pos - from).normalized()
	enemies.grid.query_radius(from, reach + EnemyManager.MAX_ENEMY_RADIUS, _targets)
	var hits := 0
	for e: EnemyAgent in _targets:
		var to := e.pos - from
		if to.length() > reach + e.radius:
			continue
		if absf(dir.angle_to(to)) <= ARC * 0.5 or to.length() < 0.8:
			hit(e, to.normalized())
			hits += 1
	if hits > 0:
		Audio.play(&"weapon_machete_hit", minf(4.0, hits - 1.0))
	Effects.find(get_tree()).slash(from, dir, reach, data.color)
	Audio.play(data.sound_id)
