extends GutTest
## Sorteio de upgrades (UpgradePicker) + carregamento de data/upgrades/.

var rng: RandomNumberGenerator
var weapon_a: WeaponData
var weapon_b: WeaponData


func before_each() -> void:
	rng = RandomNumberGenerator.new()
	rng.seed = 1234
	weapon_a = WeaponData.new()
	weapon_a.id = &"a"
	weapon_b = WeaponData.new()
	weapon_b.id = &"b"


func _u(id: String, kind: UpgradeData.Kind, weapon: WeaponData = null, max_picks: int = 5,
		weight: float = 1.0) -> UpgradeData:
	var u := UpgradeData.new()
	u.id = StringName(id)
	u.kind = kind
	u.weapon = weapon
	u.max_picks = max_picks
	u.weight = weight
	return u


func test_returns_requested_amount_without_duplicates() -> void:
	var all: Array[UpgradeData] = []
	for i: int in 6:
		all.append(_u("p%d" % i, UpgradeData.Kind.PLAYER_STAT))
	var picked := UpgradePicker.pick(all, {}, [], 3, rng)
	assert_eq(picked.size(), 3)
	var ids := {}
	for u: UpgradeData in picked:
		ids[u.id] = true
	assert_eq(ids.size(), 3, "sem cartas repetidas")


func test_respects_max_picks() -> void:
	var maxed := _u("maxed", UpgradeData.Kind.PLAYER_STAT, null, 2)
	var all: Array[UpgradeData] = [maxed, _u("ok", UpgradeData.Kind.PLAYER_STAT)]
	var picked := UpgradePicker.pick(all, {&"maxed": 2}, [], 3, rng)
	assert_does_not_have(picked, maxed)


func test_new_weapon_only_if_not_owned() -> void:
	var unlock := _u("unlock_a", UpgradeData.Kind.NEW_WEAPON, weapon_a, 1)
	var owned: Array[StringName] = [&"a"]
	assert_false(UpgradePicker.is_available(unlock, {}, owned))
	assert_true(UpgradePicker.is_available(unlock, {}, []))


func test_weapon_stat_only_if_owned() -> void:
	var buff_b := _u("buff_b", UpgradeData.Kind.WEAPON_STAT, weapon_b)
	var owned: Array[StringName] = [&"a"]
	assert_false(UpgradePicker.is_available(buff_b, {}, owned))
	owned.append(&"b")
	assert_true(UpgradePicker.is_available(buff_b, {}, owned))


func test_heal_only_fills_missing_slots() -> void:
	var heal := _u("heal", UpgradeData.Kind.HEAL, null, 0)
	var all: Array[UpgradeData] = [heal]
	for i: int in 3:
		all.append(_u("p%d" % i, UpgradeData.Kind.PLAYER_STAT))
	assert_does_not_have(UpgradePicker.pick(all, {}, [], 3, rng), heal, "ha opcoes suficientes")
	all = [heal, _u("only", UpgradeData.Kind.PLAYER_STAT)]
	var picked := UpgradePicker.pick(all, {}, [], 3, rng)
	assert_eq(picked.size(), 2)
	assert_has(picked, heal)


func test_weight_zero_never_picked_when_others_exist() -> void:
	var never := _u("never", UpgradeData.Kind.PLAYER_STAT, null, 5, 0.0)
	var all: Array[UpgradeData] = [never, _u("x", UpgradeData.Kind.PLAYER_STAT)]
	for i: int in 50:
		assert_eq(UpgradePicker.pick(all, {}, [], 1, rng)[0].id, &"x")


func test_evolution_requires_level_and_combo() -> void:
	var base := WeaponData.new()
	base.id = &"pistol"
	var evo := _u("evolve", UpgradeData.Kind.EVOLVE, base, 1)
	evo.evolves_to = WeaponData.new()
	evo.requires_weapon_level = 5
	evo.requires_upgrades = [&"p_crit"] as Array[StringName]
	var owned: Array[StringName] = [&"pistol"]
	assert_false(UpgradePicker.is_available(evo, {}, owned, {&"pistol": 5}), "falta a passiva")
	assert_false(UpgradePicker.is_available(evo, {&"p_crit": 1}, owned, {&"pistol": 3}), "nivel baixo")
	assert_true(UpgradePicker.is_available(evo, {&"p_crit": 1}, owned, {&"pistol": 5}))


func test_available_evolution_always_offered() -> void:
	var base := WeaponData.new()
	base.id = &"pistol"
	var evo := _u("evolve", UpgradeData.Kind.EVOLVE, base, 1, 0.01)
	evo.evolves_to = WeaponData.new()
	var all: Array[UpgradeData] = [evo]
	for i: int in 6:
		all.append(_u("p%d" % i, UpgradeData.Kind.PLAYER_STAT))
	var owned: Array[StringName] = [&"pistol"]
	for i: int in 10:
		assert_has(UpgradePicker.pick(all, {}, owned, 3, rng, {&"pistol": 1}), evo)


func test_weapon_slots_are_limited() -> void:
	var w := WeaponData.new()
	w.id = &"new"
	var unlock := _u("unlock", UpgradeData.Kind.NEW_WEAPON, w, 1)
	var owned: Array[StringName] = []
	for i: int in UpgradePicker.MAX_WEAPONS:
		owned.append(StringName("w%d" % i))
	assert_false(UpgradePicker.is_available(unlock, {}, owned))


func test_library_loads_all_project_upgrades() -> void:
	var all := UpgradeLibrary.load_all()
	assert_gt(all.size(), 20)
	var ids := {}
	for u: UpgradeData in all:
		assert_false(ids.has(u.id), "id repetido: %s" % u.id)
		ids[u.id] = true
		match u.kind:
			UpgradeData.Kind.NEW_WEAPON:
				assert_not_null(u.weapon, "%s precisa de weapon" % u.resource_path)
				assert_not_null(u.weapon.scene, "%s: arma sem cena" % u.resource_path)
			UpgradeData.Kind.WEAPON_STAT, UpgradeData.Kind.PLAYER_STAT:
				var target: Object = Weapon.new() if u.kind == UpgradeData.Kind.WEAPON_STAT else PlayerStats.new()
				assert_true(u.stat in target, "%s: stat '%s' nao existe" % [u.resource_path, u.stat])
				if target is Node:
					(target as Node).free()
			UpgradeData.Kind.EVOLVE:
				assert_not_null(u.evolves_to, "%s precisa de evolves_to" % u.resource_path)
