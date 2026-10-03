extends GutTest
## Ondas e dificuldade: escolha da onda ativa, timeline do Rio e diretor.


func _wave(t: float) -> WaveData:
	var w := WaveData.new()
	w.start_time = t
	return w


func test_get_wave_at_picks_latest_started() -> void:
	var tl := WaveTimeline.new()
	var w0 := _wave(0)
	var w60 := _wave(60)
	var w120 := _wave(120)
	tl.waves = [w0, w120, w60]  # fora de ordem de proposito
	assert_same(tl.get_wave_at(0), w0)
	assert_same(tl.get_wave_at(59.9), w0)
	assert_same(tl.get_wave_at(60), w60)
	assert_same(tl.get_wave_at(5000), w120, "depois do fim continua na ultima (ranqueado)")


func test_get_wave_before_first_is_null() -> void:
	var tl := WaveTimeline.new()
	tl.waves = [_wave(10)]
	assert_null(tl.get_wave_at(5))


func test_rio_timeline_is_valid() -> void:
	var map := load("res://data/maps/rio.tres") as MapData
	assert_not_null(map.timeline)
	assert_not_null(map.timeline.get_wave_at(0), "precisa de onda no inicio")
	var first := map.timeline.get_wave_at(0)
	var last := map.timeline.get_wave_at(1799)
	assert_gt(last.max_alive, first.max_alive)
	for w: WaveData in map.timeline.waves:
		assert_false(w.enemies.is_empty(), "onda %ss sem inimigos" % w.start_time)
		assert_gt(w.spawn_interval, 0.0)
	assert_false(map.difficulty_profile.bosses.is_empty(), "precisa de chefes")


func test_director_grows_over_time() -> void:
	var d := DifficultyDirector.new(DifficultyProfile.new(), 1800.0)
	assert_gt(d.health_mult(600), d.health_mult(0))
	assert_gt(d.damage_mult(600), d.damage_mult(0))
	assert_gt(d.elite_chance(1200), d.elite_chance(0))
	assert_gt(d.horde_size(1200), d.horde_size(0))


func test_director_speed_and_spawn_are_capped() -> void:
	var p := DifficultyProfile.new()
	var d := DifficultyDirector.new(p, 1800.0)
	assert_almost_eq(d.speed_mult(36000), p.max_speed_mult, 0.001, "velocidade tem teto")
	assert_almost_eq(d.spawn_rate_mult(36000), p.max_spawn_rate_mult, 0.001)
	assert_almost_eq(d.elite_chance(36000), p.elite_chance_max, 0.001)


func test_director_overtime_accelerates_after_timeline() -> void:
	var p := DifficultyProfile.new()
	p.overtime_growth_mult = 2.0
	var d := DifficultyDirector.new(p, 600.0)
	# 60 s depois do fim valem 2 "minutos" de dificuldade.
	assert_almost_eq(d.effective_minutes(660), 12.0, 0.001)
	assert_almost_eq(d.effective_minutes(300), 5.0, 0.001)


func test_director_boss_schedule() -> void:
	var p := DifficultyProfile.new()
	p.boss_interval = 300.0
	p.bosses = [EnemyData.new()] as Array[EnemyData]
	var d := DifficultyDirector.new(p, 1800.0)
	assert_eq(d.boss_index(100), -1)
	assert_eq(d.boss_index(300), 0)
	assert_eq(d.boss_index(650), 1)
	assert_gt(d.boss_health_mult(1, 650), d.boss_health_mult(0, 650))
