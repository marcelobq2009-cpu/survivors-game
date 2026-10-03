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
	for e: EnemyAgent in _targets:
		var to := e.pos - from
		if to.length() > reach + e.radius:
			continue
		if absf(dir.angle_to(to)) <= ARC * 0.5 or to.length() < 0.8:
			hit(e, to.normalized())
	Effects.find(get_tree()).slash(from, dir, reach, data.color)
	Audio.play(data.sound_id, -6.0)
