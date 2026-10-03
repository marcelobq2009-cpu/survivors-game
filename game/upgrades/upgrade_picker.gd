class_name UpgradePicker
extends RefCounted
## Sorteia as cartas de level-up (logica pura, testavel).
## Regras:
## - respeita max_picks de cada upgrade;
## - NEW_WEAPON so aparece se o jogador ainda nao tem a arma (e tem espaco);
## - WEAPON_STAT so aparece se o jogador ja tem a arma;
## - EVOLVE so aparece com a arma no nivel exigido + upgrades exigidos;
## - sorteio com peso e sem repetir carta; evolucao disponivel sempre aparece;
## - cartas HEAL/GOLD so entram para completar quando faltam opcoes.

const MAX_WEAPONS := 6


static func is_available(u: UpgradeData, counts: Dictionary, owned: Array[StringName],
		weapon_levels: Dictionary = {}) -> bool:
	var picks: int = counts.get(u.id, 0)
	if u.max_picks > 0 and picks >= u.max_picks:
		return false
	for req: StringName in u.requires_upgrades:
		if int(counts.get(req, 0)) <= 0:
			return false
	match u.kind:
		UpgradeData.Kind.NEW_WEAPON:
			return u.weapon != null and not owned.has(u.weapon.id) and owned.size() < MAX_WEAPONS
		UpgradeData.Kind.WEAPON_STAT:
			return u.weapon == null or owned.has(u.weapon.id)
		UpgradeData.Kind.EVOLVE:
			return u.weapon != null and u.evolves_to != null and owned.has(u.weapon.id) \
					and int(weapon_levels.get(u.weapon.id, 0)) >= u.requires_weapon_level
	return true


static func pick(all: Array[UpgradeData], counts: Dictionary, owned: Array[StringName],
		amount: int, rng: RandomNumberGenerator, weapon_levels: Dictionary = {}) -> Array[UpgradeData]:
	var evolutions: Array[UpgradeData] = []
	var main: Array[UpgradeData] = []
	var fallback: Array[UpgradeData] = []
	for u: UpgradeData in all:
		if not is_available(u, counts, owned, weapon_levels):
			continue
		match u.kind:
			UpgradeData.Kind.HEAL, UpgradeData.Kind.GOLD:
				fallback.append(u)
			UpgradeData.Kind.EVOLVE:
				evolutions.append(u)
			_:
				main.append(u)
	var result := _weighted_sample(evolutions, mini(1, amount), rng)
	result.append_array(_weighted_sample(main, amount - result.size(), rng))
	if result.size() < amount:
		result.append_array(_weighted_sample(fallback, amount - result.size(), rng))
	return result


static func _weighted_sample(pool: Array[UpgradeData], amount: int,
		rng: RandomNumberGenerator) -> Array[UpgradeData]:
	var remaining := pool.duplicate()
	var result: Array[UpgradeData] = []
	while result.size() < amount and not remaining.is_empty():
		var total := 0.0
		for u: UpgradeData in remaining:
			total += maxf(0.0, u.weight)
		var roll := rng.randf() * total
		var chosen_index := remaining.size() - 1
		for i: int in remaining.size():
			roll -= maxf(0.0, (remaining[i] as UpgradeData).weight)
			if roll < 0.0:
				chosen_index = i
				break
		result.append(remaining[chosen_index])
		remaining.remove_at(chosen_index)
	return result
