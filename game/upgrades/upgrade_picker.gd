class_name UpgradePicker
extends RefCounted
## Sorteia as cartas de level-up (logica pura, testavel).
## Regras:
## - respeita max_picks de cada upgrade;
## - NEW_WEAPON so aparece se o jogador ainda nao tem a arma;
## - WEAPON_STAT so aparece se o jogador ja tem a arma;
## - sorteio com peso e sem repetir carta;
## - cartas HEAL so entram para completar quando faltam opcoes.


static func is_available(u: UpgradeData, counts: Dictionary, owned: Array[StringName]) -> bool:
	var picks: int = counts.get(u.id, 0)
	if u.max_picks > 0 and picks >= u.max_picks:
		return false
	match u.kind:
		UpgradeData.Kind.NEW_WEAPON:
			return u.weapon != null and not owned.has(u.weapon.id)
		UpgradeData.Kind.WEAPON_STAT:
			return u.weapon == null or owned.has(u.weapon.id)
	return true


static func pick(all: Array[UpgradeData], counts: Dictionary, owned: Array[StringName],
		amount: int, rng: RandomNumberGenerator) -> Array[UpgradeData]:
	var main: Array[UpgradeData] = []
	var fallback: Array[UpgradeData] = []
	for u: UpgradeData in all:
		if not is_available(u, counts, owned):
			continue
		if u.kind == UpgradeData.Kind.HEAL:
			fallback.append(u)
		else:
			main.append(u)
	var result := _weighted_sample(main, amount, rng)
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
