class_name MetaShop
extends RefCounted
## Regras da loja de melhorias permanentes (logica pura, testavel).


static func level(profile: ProfileData, m: MetaUpgradeData) -> int:
	return int(profile.meta_levels.get(String(m.id), 0))


static func is_maxed(profile: ProfileData, m: MetaUpgradeData) -> bool:
	return level(profile, m) >= m.max_level


static func next_cost(profile: ProfileData, m: MetaUpgradeData) -> int:
	return m.cost_for_level(level(profile, m))


static func can_buy(profile: ProfileData, m: MetaUpgradeData) -> bool:
	return not is_maxed(profile, m) and profile.gold >= next_cost(profile, m)


## Compra um nivel. Retorna true se comprou (gasta o ouro).
static func buy(profile: ProfileData, m: MetaUpgradeData) -> bool:
	if not can_buy(profile, m):
		return false
	profile.gold -= next_cost(profile, m)
	profile.meta_levels[String(m.id)] = level(profile, m) + 1
	return true


## Aplica todas as melhorias compradas nos stats do jogador (inicio da partida).
static func apply(profile: ProfileData, metas: Array[MetaUpgradeData], stats: PlayerStats) -> void:
	for m: MetaUpgradeData in metas:
		var lvl := level(profile, m)
		if lvl > 0:
			stats.apply(m.stat, m.value_per_level * lvl, false)
