extends GutTest
## Sistema de audio: catalogo, sintese, musica, prioridade e configuracoes.


func test_every_catalog_sound_generates_valid_audio() -> void:
	var start := Time.get_ticks_msec()
	var catalog := SoundCatalog.build()
	assert_gt(catalog.size(), 50, "catalogo completo")
	for id: StringName in catalog:
		var def: SoundCatalog.Def = catalog[id]
		var rng := RandomNumberGenerator.new()
		rng.seed = 7
		var data: PackedFloat32Array = def.recipe.call(rng)
		assert_gt(data.size(), 200, "%s gerou audio" % id)
		var peak := 0.0
		var bad := false
		for v: float in data:
			if is_nan(v) or is_inf(v):
				bad = true
				break
			peak = maxf(peak, absf(v))
		assert_false(bad, "%s sem NaN/infinito" % id)
		assert_gt(peak, 0.01, "%s nao e silencio" % id)
		assert_true(peak <= 1.05, "%s sem estourar" % id)
	gut.p("Geracao de todos os efeitos: %d ms" % (Time.get_ticks_msec() - start))


func test_catalog_categories_and_loops() -> void:
	var catalog := SoundCatalog.build()
	var buses := [SoundCatalog.BUS_SFX, SoundCatalog.BUS_AMBIENCE, SoundCatalog.BUS_ZOMBIES,
		SoundCatalog.BUS_UI, SoundCatalog.BUS_BOSSES, SoundCatalog.BUS_ALERTS]
	for id: StringName in catalog:
		var def: SoundCatalog.Def = catalog[id]
		assert_has(buses, def.bus, "%s em canal valido" % id)
		assert_true(def.priority >= 0 and def.priority <= 100)
	for loop_id: StringName in [&"amb_city", &"amb_beach", &"amb_hills", &"weapon_gas_loop",
			&"weapon_fire_loop", &"zombie_horde_loop", &"player_heartbeat"]:
		assert_true((catalog[loop_id] as SoundCatalog.Def).loop, "%s e loop" % loop_id)
	# Ameacas importantes tem prioridade alta e legenda.
	for alert: StringName in [&"zombie_bloater_fuse", &"boss_charge", &"elite_appear"]:
		var d: SoundCatalog.Def = catalog[alert]
		assert_gt(d.priority, 75)
		assert_ne(d.caption, "", "%s tem legenda" % alert)


func test_every_weapon_sound_exists() -> void:
	var catalog := SoundCatalog.build()
	for f: String in ResourceLoader.list_directory("res://data/weapons/"):
		if not f.ends_with(".tres"):
			continue
		var w := load("res://data/weapons/" + f) as WeaponData
		assert_true(catalog.has(w.sound_id), "%s: som %s existe" % [w.id, w.sound_id])
		assert_true(catalog.has(w.impact_sound_id), "%s: impacto %s existe" % [w.id, w.impact_sound_id])


func test_music_track_layers_are_same_length_and_loop() -> void:
	var start := Time.get_ticks_msec()
	var composer := MusicComposer.new()
	var layers: Array[PackedFloat32Array] = await composer.render_track(&"menu")
	assert_eq(layers.size(), 2)
	assert_eq(layers[0].size(), layers[1].size(), "camadas sincronizadas")
	var stream := Synth.to_stream(layers[0], true)
	assert_eq(stream.loop_mode, AudioStreamWAV.LOOP_FORWARD)
	gut.p("Composicao da trilha do menu: %d ms" % (Time.get_ticks_msec() - start))


func test_synth_stream_conversion() -> void:
	var tone := Synth.tone(440.0, 0.1)
	var s := Synth.to_stream(tone)
	assert_eq(s.data.size(), tone.size() * 2, "16 bits por amostra")
	assert_almost_eq(s.get_length(), 0.1, 0.01)


func test_buses_exist() -> void:
	for bus: StringName in [&"Music", &"SFX", &"Ambience", &"Zombies", &"UI", &"Bosses", &"Alerts"]:
		assert_gt(AudioServer.get_bus_index(bus), 0, "canal %s criado" % bus)


func test_settings_roundtrip_audio_options() -> void:
	var s := GameSettings.new()
	s.zombies_volume = 0.3
	s.mono_audio = true
	s.captions = false
	s.fps_limit = 30
	var back := GameSettings.from_dict(s.to_dict())
	assert_almost_eq(back.zombies_volume, 0.3, 0.001)
	assert_true(back.mono_audio)
	assert_false(back.captions)
	assert_eq(back.fps_limit, 30)


func test_cooldown_blocks_spam() -> void:
	# Mesmo som em sequencia muito rapida nao toca duas vezes (evita "metralhar").
	var def: SoundCatalog.Def = Audio.catalog[&"zombie_runner_screech"]
	Audio._last_ms.erase(def.id)
	assert_true(Audio._allowed(def))
	assert_false(Audio._allowed(def), "bloqueado pelo intervalo minimo")
