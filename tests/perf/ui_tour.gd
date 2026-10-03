extends Node
## Tour visual automatico (nao e teste GUT): passa pelas telas da partida em
## momentos fixos, para conferir o visual gravando frames:
##   scripts/godot.(ps1|sh) --path . res://tests/perf/ui_tour.tscn --write-movie <pasta>/f.png --fixed-fps 30 --quit-after 420
## Frames aproximados: 90 jogo | 130 level-up | 190 bau | 250 pausa | 300 debug | 400 resultado

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
			DebugPanel.find(get_tree()).toggle()
		320:
			DebugPanel.find(get_tree()).toggle()
			_world.end_run(false)
		419:
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
