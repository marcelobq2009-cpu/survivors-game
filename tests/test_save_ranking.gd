extends GutTest
## Save (perfil em JSON, migracao), ranking mock, grade do mapa e conteudo.


func test_profile_roundtrip_keeps_everything() -> void:
	var p := ProfileData.new()
	p.player_name = "Teste"
	p.gold = 321
	p.total_kills = 999
	p.best_time_by_map["rio"] = 123.5
	p.completed_maps.append("rio")
	p.unlocked.append("soldier")
	p.achievements.append("boss_killer")
	p.tutorial_done = true
	p.settings.music_volume = 0.25
	p.settings.quality = GameSettings.Quality.HIGH
	var json := JSON.stringify(p.to_dict())
	var back := ProfileData.from_dict(JSON.parse_string(json) as Dictionary)
	assert_eq(back.player_name, "Teste")
	assert_eq(back.gold, 321)
	assert_eq(back.total_kills, 999)
	assert_almost_eq(float(back.best_time_by_map["rio"]), 123.5, 0.001)
	assert_has(back.completed_maps, "rio")
	assert_has(back.unlocked, "soldier")
	assert_has(back.achievements, "boss_killer")
	assert_true(back.tutorial_done)
	assert_almost_eq(back.settings.music_volume, 0.25, 0.001)
	assert_eq(back.settings.quality, GameSettings.Quality.HIGH)


func test_profile_from_garbage_uses_defaults() -> void:
	var p := ProfileData.from_dict({"gold": "abc", "unlocked": 5, "settings": "x"})
	assert_eq(p.gold, 0)
	assert_eq(p.unlocked.size(), 0)
	assert_not_null(p.settings)


func test_settings_are_clamped() -> void:
	var s := GameSettings.from_dict({"music_volume": 5.0, "quality": 99})
	assert_eq(s.music_volume, 1.0)
	assert_eq(s.quality, 2)


func test_local_ranking_is_deterministic_and_sorted() -> void:
	var provider := LocalRankingProvider.new()
	watch_signals(provider)
	provider.request_leaderboard("rio", 10)
	await wait_process_frames(2)
	assert_signal_emitted(provider, "leaderboard_ready")
	var params: Array = get_signal_parameters(provider, "leaderboard_ready")
	var entries: Array = params[1]
	assert_eq(entries.size(), 10)
	for i: int in range(1, entries.size()):
		assert_true((entries[i - 1] as RankingEntry).score >= (entries[i] as RankingEntry).score)
	assert_eq((entries[0] as RankingEntry).rank, 1)


func test_local_ranking_includes_player_best() -> void:
	var provider := LocalRankingProvider.new()
	provider.submit(RankingEntry.make("Eu", "survivor", "rio", 99999, 99999999, true))
	watch_signals(provider)
	provider.request_leaderboard("rio", 5)
	await wait_process_frames(2)
	var entries: Array = get_signal_parameters(provider, "leaderboard_ready")[1]
	assert_true((entries[0] as RankingEntry).is_player, "pontuacao enorme fica em 1o")
	assert_eq(provider.position_for_score("rio", 99999999), 1)
	assert_gt(provider.position_for_score("rio", 0), 50)


func test_map_grid_blocks_and_finds_free() -> void:
	var g := MapGrid.new(Rect2(-10, -10, 20, 20), 1.0)
	g.block_rect(Vector2.ZERO, Vector2(4, 4))
	assert_true(g.is_blocked(Vector2(0.5, 0.5)))
	assert_false(g.is_blocked(Vector2(5, 5)))
	assert_true(g.is_blocked(Vector2(50, 0)), "fora do mapa conta como parede")
	var free := g.nearest_free(Vector2(0.2, 0.2))
	assert_true(g.is_free(free))


func test_content_registry_loads_data() -> void:
	assert_gt(Content.characters.size(), 2)
	assert_gt(Content.maps.size(), 1)
	assert_gt(Content.achievements.size(), 3)
	assert_not_null(Content.find_map(&"rio"))
	assert_true(Content.find_map(&"rio").unlock_requirements.is_empty(), "Rio comeca liberado")
	assert_true(Content.find_character(&"survivor").unlock_requirements.is_empty())
	assert_false(Content.find_character(&"soldier").unlock_requirements.is_empty())
	for c: CharacterData in Content.characters:
		assert_not_null(c.starting_weapon, "%s precisa de arma inicial" % c.id)
	for m: MapData in Content.maps:
		if not m.coming_soon:
			assert_not_null(m.scene, "%s precisa de cena" % m.id)
