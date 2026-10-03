extends Node
## Robo de playtest (nao e teste GUT). Joga sozinho: foge da horda andando em
## volta dela e escolhe a 1a carta de cada level-up. A cada minuto imprime
## nivel, abates, vida, zumbis e custo por frame. Para no fim ou na morte.
## Rodar (sem janela, o mais rapido possivel):
##   scripts/godot.(ps1|sh) --headless res://tests/perf/playtest_bot.tscn --fixed-fps 60
## Opcoes (depois de --): ranked  |  minutes=N  |  character=soldier

const WORLD_SCENE := preload("res://game/world/world.tscn")

var _world: World
var _minutes: float = 30.0
var _next_report: float = 60.0
var _frame_ms: Array[float] = []
var _orbit: float = 1.0
var _done: bool = false
var _bosses_seen: int = 0
var _god: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Save.set_storage_path("user://bot_save.json")
	Save.reset_progress()
	Save.profile.tutorial_done = true
	var setup := RunSetup.new()
	setup.map = Content.find_map(&"rio")
	setup.character = Content.find_character(&"survivor")
	for arg: String in OS.get_cmdline_user_args():
		if arg == "ranked":
			setup.mode = RunSetup.Mode.RANKED
		elif arg == "god":
			_god = true
		elif arg.begins_with("minutes="):
			_minutes = float(arg.split("=")[1])
		elif arg.begins_with("character="):
			setup.character = Content.find_character(StringName(arg.split("=")[1]))
	GameState.setup = setup
	Events.run_ended.connect(_on_end)
	Events.boss_spawned.connect(func(_d: EnemyData) -> void: _bosses_seen += 1)
	_world = WORLD_SCENE.instantiate() as World
	_world.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(_world)
	print("BOT inicio: modo=%s personagem=%s" % [setup.mode_name(), setup.character.id])


func _physics_process(_delta: float) -> void:
	if _done:
		return
	_frame_ms.append(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0)
	_pick_cards()
	_steer()
	if _god and Player.find(get_tree()):
		Player.find(get_tree()).health.god_mode = true
	if GameState.elapsed >= _next_report:
		_report()
		_next_report += 60.0
	if GameState.elapsed >= _minutes * 60.0 and GameState.is_running:
		print("BOT limite de tempo atingido")
		_finish()


## Anda em volta do "centro" dos zumbis proximos (kiting), longe das paredes.
func _steer() -> void:
	var m := EnemyManager.find(get_tree())
	var map := GameMap.find(get_tree())
	if m == null or map == null or not GameState.is_running:
		return
	var me := GameState.player_position
	var away := Vector2.ZERO
	var closest := INF
	for a: EnemyAgent in m.agents:
		var d := me - a.pos
		var l := d.length()
		closest = minf(closest, l)
		if l < 9.0 and l > 0.01:
			away += d / (l * l)
	var dir := away.normalized().rotated(_orbit * 1.1) if away != Vector2.ZERO else Vector2.RIGHT.rotated(GameState.elapsed * 0.3)
	# Jogador medio: sem zumbi colado, vai buscar XP.
	var pickups := PickupManager.find(get_tree())
	if closest > 3.5 and pickups:
		var gem := pickups.nearest_pickup(me, 14.0)
		if gem != Vector2.INF:
			dir = (gem - me).normalized()
	if map.grid.is_blocked(me + dir * 2.5):
		_orbit = -_orbit
		dir = dir.rotated(PI * 0.5 * _orbit)
	# Converte direcao do chao para "teclas" (inverso da camera).
	var rig := CameraRig.find(get_tree())
	var right := GroundPlane.to_2d(rig.camera.global_basis.x).normalized()
	var up := -GroundPlane.to_2d(rig.camera.global_basis.z).normalized()
	var input := Vector2(dir.dot(right), -dir.dot(up))
	_press(&"move_left", -input.x)
	_press(&"move_right", input.x)
	_press(&"move_up", -input.y)
	_press(&"move_down", input.y)


func _press(action: StringName, v: float) -> void:
	if v > 0.05:
		Input.action_press(action, minf(1.0, v))
	else:
		Input.action_release(action)


func _pick_cards() -> void:
	var screen := _world.get_node_or_null("LevelUpScreen") as LevelUpScreen
	if screen == null or not screen.is_open():
		return
	var cards := screen.find_children("*", "Button", true, false)
	for c: Node in cards:
		var b := c as Button
		if b and not b.disabled and b.get_parent() is HBoxContainer:
			b.pressed.emit()
			return


func _report() -> void:
	var m := EnemyManager.find(get_tree())
	var p := Player.find(get_tree())
	_frame_ms.sort()
	var avg := 0.0
	for f: float in _frame_ms:
		avg += f
	avg /= maxf(1.0, _frame_ms.size())
	var p95 := _frame_ms[int(_frame_ms.size() * 0.95)] if not _frame_ms.is_empty() else 0.0
	print("BOT %s | dif %.2fx vida %.2fx dano | nv %d | abates %d | vida %d/%d | zumbis %d | armas %d | chefes vistos %d | fisica %.2f ms (p95 %.2f)" % [
		UiKit.time_text(GameState.elapsed), _director().health_mult(GameState.elapsed), _director().damage_mult(GameState.elapsed), GameState.level, GameState.kills,
		ceili(p.health.current) if p else 0, roundi(p.health.max_value) if p else 0,
		m.count() if m else 0, GameState.owned_weapons.size(), _bosses_seen, avg, p95])
	_frame_ms.clear()


func _on_end(r: RunResult) -> void:
	print("BOT FIM: %s em %s | nv %d | abates %d | chefes %d | ouro +%d | desbloqueios %d" % [
		"VITORIA" if r.victory else "MORTE", UiKit.time_text(r.time), r.level, r.kills,
		r.bosses_killed, r.gold_reward, r.new_unlocks.size()])
	_finish()


func _finish() -> void:
	if _done:
		return
	_done = true
	Save.set_storage_path(Save.DEFAULT_PATH)
	get_tree().quit()


func _director() -> DifficultyDirector:
	return EnemySpawner.find(get_tree()).director
