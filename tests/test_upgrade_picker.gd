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


func test_library_loads_all_project_upgrades() -> void:
	var all := UpgradeLibrary.load_all()
	assert_gt(all.size(), 5)
	for u: UpgradeData in all:
		assert_ne(u.id, &"upgrade", "%s precisa de um id proprio" % u.resource_path)
		if u.kind != UpgradeData.Kind.PLAYER_STAT and u.kind != UpgradeData.Kind.HEAL:
			assert_not_null(u.weapon, "%s precisa de weapon" % u.resource_path)
