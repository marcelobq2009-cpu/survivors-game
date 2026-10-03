class_name World
extends Node3D
## Cena da partida. Monta o mapa e o jogador escolhidos (GameState.setup),
## conta o tempo e encerra a partida (morte, ou fim do tempo no modo normal).
## Ao terminar: recompensas, desbloqueios, conquistas, ranking e save.
## Os sistemas filhos conversam via Events.

const PLAYER_SCENE: PackedScene = preload("res://game/player/player.tscn")
const END_DELAY := 1.4  # segundos de "camera lenta" antes do resultado

var _duration: float = 0.0
var _last_minute_warned: bool = false
var _ending: bool = false

@onready var map_holder: Node3D = $Map
@onready var enemies: EnemyManager = $EnemyManager
@onready var spawner: EnemySpawner = $EnemySpawner


func _ready() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	Pool.clear()
	var setup := GameState.setup
	_fill_missing_setup(setup)
	GameState.reset()

	var map := setup.map.scene.instantiate() as GameMap
	map_holder.add_child(map)
	var player := PLAYER_SCENE.instantiate() as Player
	player.character = setup.character
	add_child(player)
	player.teleport(map.player_spawn)

	spawner.setup(setup.map.timeline, setup.map.difficulty_profile, enemies)
	GraphicsSettings.apply(get_tree(), Save.profile.settings)
	_duration = setup.duration()
	GameState.is_running = true
	Events.player_died.connect(_end_run.bind(false))
	Events.run_started.emit()
	Events.xp_changed.emit(0, GameState.progression.xp_needed(), 1)
	Audio.play_music(setup.map.music_id)


func _exit_tree() -> void:
	GameState.is_running = false
	Engine.time_scale = 1.0
	Pool.clear()


func _physics_process(delta: float) -> void:
	if not GameState.is_running:
		return
	GameState.elapsed += delta
	if _duration > 0.0:
		if not _last_minute_warned and GameState.elapsed >= _duration - 60.0 and _duration > 120.0:
			_last_minute_warned = true
			Events.announcement.emit("ULTIMO MINUTO! AGUENTE FIRME!", Color(0.5, 1, 0.6))
		if GameState.elapsed >= _duration:
			_end_run(true)


## Encerra a partida (vitoria ou derrota).
func _end_run(victory: bool) -> void:
	if not GameState.is_running or _ending:
		return
	_ending = true
	GameState.is_running = false
	var result := GameState.build_result(victory)
	var profile := Save.profile
	ProgressService.finalize_run(profile, result, Config.game, Content.achievements, Content.unlockables())
	profile.last_character_id = result.character_id
	profile.last_map_id = result.map_id
	if result.is_ranked():
		Ranking.submit(RankingEntry.make(profile.player_name, result.character_id, result.map_id,
				result.time, result.score, true))
		result.rank_position = Ranking.position_for_score(result.map_id, result.score)
	Save.save_data()
	Audio.play(&"victory" if victory else &"defeat")
	# Camera lenta e depois a tela de resultado (com o jogo pausado).
	Engine.time_scale = 0.35
	await get_tree().create_timer(END_DELAY, true, false, true).timeout
	Engine.time_scale = 1.0
	get_tree().paused = true
	Events.run_ended.emit(result)


## Permite abrir world.tscn direto (testes/debug) sem passar pelo menu.
func _fill_missing_setup(setup: RunSetup) -> void:
	if setup.map == null and not Content.maps.is_empty():
		setup.map = Content.maps[0]
	if setup.character == null and not Content.characters.is_empty():
		setup.character = Content.characters[0]
