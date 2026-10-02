extends GutTest
## Ondas: escolha da onda ativa e validade da timeline do jogo.


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
	assert_same(tl.get_wave_at(500), w120)


func test_get_wave_before_first_is_null() -> void:
	var tl := WaveTimeline.new()
	tl.waves = [_wave(10)]
	assert_null(tl.get_wave_at(5))


func test_main_timeline_is_valid_and_gets_harder() -> void:
	var tl := load("res://data/waves/main_timeline.tres") as WaveTimeline
	assert_not_null(tl)
	assert_almost_eq(tl.run_duration, 600.0, 60.0, "partida de ~10 min")
	assert_not_null(tl.get_wave_at(0), "precisa de onda no inicio")
	var first := tl.get_wave_at(0)
	var last := tl.get_wave_at(tl.run_duration - 1)
	assert_gt(last.max_alive, first.max_alive)
	assert_gt(last.health_multiplier, first.health_multiplier)
	for w: WaveData in tl.waves:
		assert_false(w.enemies.is_empty(), "onda %ss sem inimigos" % w.start_time)
		assert_gt(w.spawn_interval, 0.0)
