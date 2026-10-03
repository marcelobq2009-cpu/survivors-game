extends GutTest
## Loja de melhorias permanentes, raridade das cartas e dados novos.


func _meta(cost: int = 50, max_level: int = 3) -> MetaUpgradeData:
	var m := MetaUpgradeData.new()
	m.id = &"vitality"
	m.stat = &"max_health"
	m.value_per_level = 10.0
	m.max_level = max_level
	m.base_cost = cost
	m.cost_growth = 2.0
	return m


func test_cost_grows_per_level() -> void:
	var m := _meta(50)
	assert_eq(m.cost_for_level(0), 50)
	assert_eq(m.cost_for_level(1), 100)
	assert_eq(m.cost_for_level(2), 200)


func test_buy_spends_gold_and_levels_up() -> void:
	var p := ProfileData.new()
	p.gold = 120
	var m := _meta(50)
	assert_true(MetaShop.buy(p, m))
	assert_eq(p.gold, 70)
	assert_eq(MetaShop.level(p, m), 1)
	assert_false(MetaShop.buy(p, m), "100 de custo, so tem 70")
	assert_eq(p.gold, 70, "nao gasta se nao comprou")


func test_cannot_buy_past_max() -> void:
	var p := ProfileData.new()
	p.gold = 100000
	var m := _meta(10, 2)
	assert_true(MetaShop.buy(p, m))
	assert_true(MetaShop.buy(p, m))
	assert_true(MetaShop.is_maxed(p, m))
	assert_false(MetaShop.buy(p, m))


func test_apply_adds_bonus_to_stats() -> void:
	var p := ProfileData.new()
	p.meta_levels["vitality"] = 3
	var s := PlayerStats.new()
	s.max_health = 100.0
	MetaShop.apply(p, [_meta()] as Array[MetaUpgradeData], s)
	assert_eq(s.max_health, 130.0)


func test_meta_levels_survive_save() -> void:
	var p := ProfileData.new()
	p.meta_levels["strength"] = 2
	var back := ProfileData.from_dict(JSON.parse_string(JSON.stringify(p.to_dict())) as Dictionary)
	assert_eq(int(back.meta_levels["strength"]), 2)


func test_project_meta_upgrades_are_valid() -> void:
	assert_gt(Content.meta_upgrades.size(), 5)
	for m: MetaUpgradeData in Content.meta_upgrades:
		assert_true(m.stat in PlayerStats.new(), "%s: stat %s existe" % [m.id, m.stat])
		assert_gt(m.base_cost, 0)
		assert_false(m.effect_text(1).contains("{"), "%s: texto sem marcadores" % m.id)


func test_rarities_assigned() -> void:
	var evo := load("res://data/upgrades/evolve_pistol.tres") as UpgradeData
	assert_eq(evo.rarity, UpgradeData.Rarity.LEGENDARY)
	var unlock := load("res://data/upgrades/unlock_shotgun.tres") as UpgradeData
	assert_eq(unlock.rarity, UpgradeData.Rarity.RARE)


func test_enemy_models_are_distinct() -> void:
	var kinds := {}
	for f: String in ResourceLoader.list_directory("res://data/enemies/"):
		if f.ends_with(".tres"):
			var e := load("res://data/enemies/" + f) as EnemyData
			kinds[e.model_kind] = true
	assert_gt(kinds.size(), 4, "cada tipo tem silhueta propria")
