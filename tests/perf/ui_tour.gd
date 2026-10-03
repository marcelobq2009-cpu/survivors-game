extends Node
## Tour visual automatico (nao e teste GUT): passa pelas telas da partida em
## momentos fixos, para conferir o visual gravando frames:
##   scripts/godot.(ps1|sh) --path . res://tests/perf/ui_tour.tscn --write-movie <pasta>/f.png --fixed-fps 30 --quit-after 600
## Frames aproximados: 130 level-up | 200 bau | 260 pausa | 300 debug | 360-470 eventos/chefe | 580 resultado

const WORLD_SCENE := preload("res://game/world/world.tscn")

var _world: World
var _frame: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Save.set_storage_path("user://tour_save.json")
	Save.reset_progress()
	Save.profile.tutorial_done = true
	GameState.setup = RunSetup.new()
	GameState.setup.map = Content.find_map(&"rio")
	GameState.setup.character = Content.find_character(&"survivor")
	_world = WORLD_SCENE.instantiate() as World
	_world.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(_world)


func _process(_delta: float) -> void:
	if not _world.has_started:
		return
	_frame += 1
	# Modo "lugar": so mostra uma regiao do mapa (beach, north).
	var args := OS.get_cmdline_user_args()
	if args.has("beach") or args.has("north"):
		if _frame == 5:
			var map := GameMap.find(get_tree()) as CityMap
			var he := map.layout.half_extents
			var spot := Vector2(-6.0, he.y - 12.0) if args.has("beach") else Vector2(he.x * 0.35 - 6.0, -he.y + 4.0)
			Player.find(get_tree()).teleport(map.grid.nearest_free(spot))
			Player.find(get_tree()).health.god_mode = true
		return
	match _frame:
		60:
			GameState.elapsed = 290.0  # chefe logo, mais zumbis
			for i: int in 3:
				GameState.add_xp(GameState.progression.xp_needed())
		110:
			pass  # level-up aberto
		160:
			_press_first_card()
			_press_first_card()
			_press_first_card()
		170:
			Events.chest_opened.emit()
		220:
			_press_first_card()
		235:
			Events.pause_requested.emit()
		280:
			Events.pause_requested.emit()
			var dbg := DebugPanel.find(get_tree())
			if dbg:
				dbg.toggle()
		320:
			var dbg := DebugPanel.find(get_tree())
			if dbg:
				dbg.toggle()
			var sp := EnemySpawner.find(get_tree())
			sp.spawn_supply_drop()
			sp.spawn_toxic_zone()
			sp.spawn_boss(0)
			var m := EnemyManager.find(get_tree())
			var p := GameState.player_position
			for id: String in ["zombie_runner", "zombie_brute", "zombie_bloater", "zombie_walker"]:
				var data := load("res://data/enemies/%s.tres" % id) as EnemyData
				m.spawn(data, p + Vector2(randf_range(-5, 5), randf_range(3, 6)))
			m.spawn(load("res://data/enemies/zombie_brute.tres") as EnemyData, p + Vector2(4, -3), 1.0, 1.0,
					1.0, true, sp.director.profile)
		480:
			Player.find(get_tree()).last_damage_source = "Colosso"
			_world.end_run(false)
		599:
			Save.set_storage_path(Save.DEFAULT_PATH)


func _press_first_card() -> void:
	var screen := _world.get_node_or_null("LevelUpScreen") as LevelUpScreen
	if screen == null or not screen.is_open():
		return
	for c: Node in screen.find_children("*", "Button", true, false):
		var b := c as Button
		if b and b.get_parent() is HBoxContainer:
			b.disabled = false
			b.pressed.emit()
			return
