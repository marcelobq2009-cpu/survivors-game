extends GutTest
## Progressao permanente: recompensas, pontuacao, recordes, desbloqueios,
## conquistas e requisitos (game/meta/).

var config: GameConfig


func before_each() -> void:
	config = GameConfig.new()


func _result(time: float, kills: int, victory: bool, ranked: bool = false) -> RunResult:
	var r := RunResult.new()
	r.map_id = "rio"
	r.character_id = "survivor"
	r.time = time
	r.kills = kills
	r.level = 10
	r.victory = victory
	r.mode = RunSetup.Mode.RANKED if ranked else RunSetup.Mode.NORMAL
	return r


func _survive(map: String, seconds: float) -> SurviveRequirement:
	var s := SurviveRequirement.new()
	s.map_id = StringName(map)
	s.seconds = seconds
	return s


func test_gold_reward_formula() -> void:
	var r := _result(600, 250, false)
	r.gold_collected = 7
	# 10 min * 10 + 2 * 5 (por 100 abates) + 7 coletado
	assert_eq(ProgressService.compute_gold_reward(r, config), 100 + 10 + 7)
	r.victory = true
	assert_eq(ProgressService.compute_gold_reward(r, config), 117 + config.victory_gold_bonus)


func test_score_formula() -> void:
	var r := _result(100, 50, false, true)
	r.bosses_killed = 1
	assert_eq(ProgressService.compute_score(r, config), 1000 + 50 + 500 + 500)


func test_apply_run_updates_stats_and_records() -> void:
	var p := ProfileData.new()
	assert_true(ProgressService.apply_run(p, _result(300, 100, false)), "primeiro tempo e recorde")
	assert_false(ProgressService.apply_run(p, _result(200, 10, false)), "tempo menor nao e recorde")
	assert_eq(p.total_runs, 2)
	assert_eq(p.total_kills, 110)
	assert_eq(float(p.best_time_by_map["rio"]), 300.0)
	assert_false(p.completed_maps.has("rio"))
	ProgressService.apply_run(p, _result(1800, 3000, true))
	assert_true(p.completed_maps.has("rio"))


func test_ranked_record_uses_score() -> void:
	var p := ProfileData.new()
	var r := _result(900, 500, false, true)
	r.score = 1000
	assert_true(ProgressService.apply_run(p, r))
	var worse := _result(950, 10, false, true)
	worse.score = 500
	assert_false(ProgressService.apply_run(p, worse))
	assert_eq(int(p.best_ranked_score["rio"]), 1000)
	assert_eq(float(p.best_ranked_time["rio"]), 950.0, "melhor tempo e separado da pontuacao")


func test_survive_requirement_uses_config_duration_when_zero() -> void:
	var p := ProfileData.new()
	var req := _survive("rio", 0.0)
	assert_almost_eq(req.needed_seconds(), Config.game.match_duration(), 0.01)
	p.best_time_by_map["rio"] = Config.game.match_duration()
	assert_true(req.is_met(p))


func test_survive_requirement_counts_ranked_time() -> void:
	var p := ProfileData.new()
	p.best_ranked_time["rio"] = 400.0
	assert_true(_survive("rio", 300.0).is_met(p))
	assert_almost_eq(_survive("rio", 800.0).progress(p), 0.5, 0.001)


func test_other_requirements() -> void:
	var p := ProfileData.new()
	var kills := KillsRequirement.new()
	kills.total_kills = 100
	var lvl := LevelRequirement.new()
	lvl.level = 5
	var boss := BossRequirement.new()
	var ach := AchievementRequirement.new()
	ach.achievement_id = &"x"
	assert_false(kills.is_met(p) or lvl.is_met(p) or boss.is_met(p) or ach.is_met(p))
	p.total_kills = 100
	p.max_level = 5
	p.bosses_killed = 1
	p.achievements.append("x")
	assert_true(kills.is_met(p) and lvl.is_met(p) and boss.is_met(p) and ach.is_met(p))


func test_unlocks_are_detected_once() -> void:
	var p := ProfileData.new()
	var c := CharacterData.new()
	c.id = &"soldier"
	c.unlock_requirements = [_survive("rio", 600.0)] as Array[UnlockRequirement]
	var free := CharacterData.new()
	free.id = &"survivor"
	var all: Array[ContentData] = [c, free]
	assert_false(ProgressService.is_unlocked(c, p))
	assert_true(ProgressService.is_unlocked(free, p), "sem requisitos = liberado")
	assert_true(ProgressService.check_unlocks(p, all).is_empty())
	p.best_time_by_map["rio"] = 700.0
	var new_ones := ProgressService.check_unlocks(p, all)
	assert_eq(new_ones.size(), 1)
	assert_same(new_ones[0], c)
	assert_true(ProgressService.check_unlocks(p, all).is_empty(), "nao anuncia duas vezes")
	assert_true(ProgressService.is_unlocked(c, p))


func test_coming_soon_never_unlocks() -> void:
	var p := ProfileData.new()
	var m := MapData.new()
	m.id = &"future"
	m.coming_soon = true
	assert_false(ProgressService.is_unlocked(m, p))
	assert_true(ProgressService.check_unlocks(p, [m] as Array[ContentData]).is_empty())


func test_achievements_give_gold_once() -> void:
	var p := ProfileData.new()
	var a := AchievementData.new()
	a.id = &"boss_killer"
	a.reward_gold = 150
	a.unlock_requirements = [BossRequirement.new()] as Array[UnlockRequirement]
	var list: Array[AchievementData] = [a]
	assert_true(ProgressService.check_achievements(p, list).is_empty())
	p.bosses_killed = 1
	assert_eq(ProgressService.check_achievements(p, list).size(), 1)
	assert_eq(p.gold, 150)
	assert_true(ProgressService.check_achievements(p, list).is_empty())
	assert_eq(p.gold, 150)


func test_finalize_run_full_flow() -> void:
	var p := ProfileData.new()
	var soldier := CharacterData.new()
	soldier.id = &"soldier"
	soldier.unlock_requirements = [_survive("rio", 0.0)] as Array[UnlockRequirement]
	var r := _result(Config.game.match_duration(), 2000, true)
	ProgressService.finalize_run(p, r, config, [] as Array[AchievementData], [soldier] as Array[ContentData])
	assert_gt(r.gold_reward, 0)
	assert_eq(p.gold, r.gold_reward)
	assert_eq(r.new_unlocks.size(), 1, "vencer o Rio libera o Militar")
	assert_true(r.new_record)
