extends GutTest
## Teste de integracao: roda a partida de verdade por alguns segundos.

const WORLD_SCENE := preload("res://game/world/world.tscn")

var world: World


func before_all() -> void:
	# O jogo pausa a arvore (level-up, game over). O GUT precisa continuar
	# rodando nesses momentos, entao ele fica "sempre ativo"...
	get_tree().root.process_mode = Node.PROCESS_MODE_ALWAYS


func after_all() -> void:
	get_tree().root.process_mode = Node.PROCESS_MODE_PAUSABLE


func before_each() -> void:
	world = WORLD_SCENE.instantiate() as World
	# ...e o mundo continua pausavel, como no jogo real.
	world.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child_autofree(world)


func after_each() -> void:
	get_tree().paused = false


func test_enemies_spawn_and_game_runs() -> void:
	await wait_physics_frames(150)
	var manager := EnemyManager.find(get_tree())
	assert_gt(manager.count(), 0, "inimigos devem nascer")
	assert_gt(GameState.elapsed, 1.0)
	assert_true(GameState.is_running)


func test_weapon_kills_enemy_and_drops_gem() -> void:
	var manager := EnemyManager.find(get_tree())
	var data := load("res://data/enemies/basic.tres") as EnemyData
	var enemy := manager.spawn(data, GameState.player_position + Vector2(120, 0))
	watch_signals(Events)
	await wait_physics_frames(120)
	assert_false(enemy.alive, "a arma inicial deve matar o inimigo perto")
	assert_signal_emitted(Events, "enemy_killed")
	assert_gt(GameState.kills, 0)


func test_level_up_pauses_and_choosing_card_resumes() -> void:
	GameState.add_xp(GameState.progression.xp_needed())
	await wait_process_frames(3)
	var screen := world.get_node("LevelUpScreen") as LevelUpScreen
	assert_true(screen.visible, "tela de level-up aparece")
	assert_true(get_tree().paused, "jogo pausa")
	await wait_seconds(1.0)
	assert_true(screen.visible, "sem toque, a tela continua aberta")
	assert_true(get_tree().paused, "e o jogo continua pausado")
	var card := screen.cards_box.get_child(0) as Button
	card.pressed.emit()
	assert_false(screen.visible)
	assert_false(get_tree().paused, "jogo volta")


func test_player_death_ends_run() -> void:
	watch_signals(Events)
	var player := world.get_node("Player") as Player
	Events.player_contact.emit(player.health.max_value + 1.0)
	await wait_process_frames(2)
	assert_signal_emitted_with_parameters(Events, "run_ended", [false])
	assert_false(GameState.is_running)
	assert_true((world.get_node("GameOverScreen") as CanvasLayer).visible)
