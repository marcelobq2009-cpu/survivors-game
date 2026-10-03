extends GutTest
## Testes de integracao: roda a partida 3D de verdade (mapa do Rio gerado).

const WORLD_SCENE := preload("res://game/world/world.tscn")

var world: World


func before_all() -> void:
	Save.set_storage_path("user://test_save.json")
	Save.reset_progress()
	Save.profile.tutorial_done = true  # tutorial pausaria o jogo nos testes
	# O jogo pausa a arvore (level-up, fim). O GUT precisa continuar rodando.
	get_tree().root.process_mode = Node.PROCESS_MODE_ALWAYS


func after_all() -> void:
	Save.set_storage_path(Save.DEFAULT_PATH)
	get_tree().root.process_mode = Node.PROCESS_MODE_PAUSABLE


func before_each() -> void:
	GameState.setup = RunSetup.new()
	GameState.setup.map = Content.find_map(&"rio")
	GameState.setup.character = Content.find_character(&"survivor")
	world = WORLD_SCENE.instantiate() as World
	world.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child_autofree(world)
	await wait_physics_frames(2)


func after_each() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0


func test_map_builds_and_player_spawns_free() -> void:
	var map := GameMap.find(get_tree())
	assert_not_null(map)
	assert_true(map.grid.is_free(GameState.player_position), "jogador nasce em lugar livre")
	assert_not_null(Player.find(get_tree()))
	assert_not_null(CameraRig.find(get_tree()))


func test_enemies_spawn_outside_walls() -> void:
	await wait_physics_frames(120)
	var manager := EnemyManager.find(get_tree())
	var map := GameMap.find(get_tree())
	assert_gt(manager.count(), 0, "zumbis devem nascer")
	for a: EnemyAgent in manager.agents:
		assert_true(map.grid.is_free(a.pos), "zumbi nao pode estar dentro de parede")


func test_weapon_kills_enemy_and_drops_xp() -> void:
	var manager := EnemyManager.find(get_tree())
	var map := GameMap.find(get_tree())
	var walker := load("res://data/enemies/zombie_walker.tres") as EnemyData
	var pos := map.grid.nearest_free(GameState.player_position + Vector2(4, 0))
	var uid := manager.spawn(walker, pos).uid
	watch_signals(Events)
	await wait_physics_frames(150)
	# O agente e reaproveitado (pool) depois de morrer: procuramos pelo uid.
	var same := manager.agents.filter(func(x: EnemyAgent) -> bool: return x.uid == uid)
	assert_true(same.is_empty() or (same[0] as EnemyAgent).hp < (same[0] as EnemyAgent).max_hp,
			"a pistola deve ferir o zumbi perto")
	assert_signal_emitted(Events, "enemy_killed")
	assert_gt(GameState.kills, 0)
	assert_gt(PickupManager.find(get_tree()).gem_count() + GameState.xp_total, 0)


func test_exploder_explodes_near_player() -> void:
	var manager := EnemyManager.find(get_tree())
	var bloater := load("res://data/enemies/zombie_bloater.tres") as EnemyData
	var a := manager.spawn(bloater, GameState.player_position + Vector2(0.5, 0))
	a.hp = 99999.0
	a.max_hp = 99999.0
	watch_signals(Events)
	await wait_physics_frames(90)
	assert_signal_emitted(Events, "explosion")


func test_boss_spawns_on_schedule() -> void:
	watch_signals(Events)
	GameState.elapsed = 301.0
	await wait_physics_frames(3)
	assert_signal_emitted(Events, "boss_spawned")
	assert_not_null(EnemyManager.find(get_tree()).current_boss())


func test_death_ends_run_and_saves() -> void:
	watch_signals(Events)
	var runs_before := Save.profile.total_runs
	var player := Player.find(get_tree())
	Events.player_contact.emit(player.health.max_value * 10.0)
	await wait_seconds(World.END_DELAY + 0.5)
	assert_signal_emitted(Events, "run_ended")
	assert_false(GameState.is_running)
	assert_eq(Save.profile.total_runs, runs_before + 1, "partida contada no save")


func test_normal_mode_victory_at_duration() -> void:
	watch_signals(Events)
	GameState.elapsed = GameState.setup.duration() - 0.01
	Player.find(get_tree()).health.god_mode = true
	await wait_seconds(World.END_DELAY + 0.5)
	assert_signal_emitted(Events, "run_ended")
	var result: RunResult = get_signal_parameters(Events, "run_ended")[0]
	assert_true(result.victory)


func test_ranked_has_no_time_limit() -> void:
	GameState.setup.mode = RunSetup.Mode.RANKED
	assert_eq(GameState.setup.duration(), 0.0)
