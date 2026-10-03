class_name DebugPanel
extends CanvasLayer
## Ferramentas de desenvolvimento dentro da partida (botao DBG no HUD).
## So existe quando Config.game.debug_tools_enabled() e true.

const GROUP := &"debug_panel"

var _root: Control
var _god_button: Button
var _hard_button: Button
var _hard: bool = false
var _rng := RandomNumberGenerator.new()


func _enter_tree() -> void:
	add_to_group(GROUP)


static func find(tree: SceneTree) -> DebugPanel:
	return tree.get_first_node_in_group(GROUP) as DebugPanel


func _ready() -> void:
	layer = 8
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rng.randomize()
	_build()
	_root.hide()


func toggle() -> void:
	if not Config.game.debug_tools_enabled():
		return
	_root.visible = not _root.visible
	if _root.visible:
		GameState.request_pause(self)
	else:
		GameState.release_pause(self)


func _build() -> void:
	_root = Control.new()
	add_child(UiKit.full_rect(_root))
	var dim := ColorRect.new()
	dim.color = Color(0, 0.05, 0, 0.6)
	_root.add_child(UiKit.full_rect(dim))
	var center := CenterContainer.new()
	_root.add_child(UiKit.full_rect(center))
	var panel := UiKit.panel(Color(0.04, 0.08, 0.04, 0.95), UiKit.TOXIC)
	center.add_child(panel)
	var col := UiKit.vbox(12)
	panel.add_child(col)
	col.add_child(UiKit.label("DEBUG", 36, UiKit.TOXIC, HORIZONTAL_ALIGNMENT_CENTER))
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override(&"h_separation", 10)
	grid.add_theme_constant_override(&"v_separation", 10)
	col.add_child(grid)
	_add(grid, "+1 MIN", func() -> void: GameState.elapsed += 60.0)
	_add(grid, "+5 MIN", func() -> void: GameState.elapsed += 300.0)
	_add(grid, "IR PARA O FIM", func() -> void:
		var d := GameState.setup.duration()
		GameState.elapsed = (d - 5.0) if d > 0.0 else GameState.elapsed + 1800.0)
	_add(grid, "+1 NÍVEL", func() -> void: GameState.add_xp(GameState.progression.xp_needed()))
	_add(grid, "+100 OURO", func() -> void: Events.gold_collected.emit(100))
	_add(grid, "+50 ZUMBIS", _spawn_zombies)
	_add(grid, "CHEFE AGORA", func() -> void:
		var s := EnemySpawner.find(get_tree())
		if s:
			s.spawn_boss(_rng.randi_range(0, 9)))
	_add(grid, "HORDA AGORA", func() -> void:
		var s := EnemySpawner.find(get_tree())
		if s:
			s.spawn_horde(40))
	_add(grid, "MATAR TODOS", func() -> void:
		var m := EnemyManager.find(get_tree())
		if m:
			m.kill_all())
	_god_button = _add(grid, "INVENCÍVEL: NÃO", _toggle_god)
	_hard_button = _add(grid, "DIFICULDADE x1", _toggle_hard)
	_add(grid, "TELEPORTAR", _teleport)
	_add(grid, "ÍMÃ TOTAL", func() -> void:
		var p := PickupManager.find(get_tree())
		if p:
			p.vacuum_all())
	_add(grid, "BAÚ", func() -> void: Events.chest_opened.emit())
	_add(grid, "DESBLOQ. TUDO", func() -> void:
		for c: ContentData in Content.unlockables():
			if not Save.profile.unlocked.has(String(c.id)):
				Save.profile.unlocked.append(String(c.id))
		Save.save_data())
	_add(grid, "VENCER AGORA", func() -> void:
		toggle()
		var w := World.find(get_tree())
		if w:
			w.end_run(true))
	var close := UiKit.button("FECHAR", Vector2(0, 70), 26, UiKit.TOXIC)
	close.pressed.connect(toggle)
	col.add_child(close)


func _add(grid: GridContainer, text: String, action: Callable) -> Button:
	var b := UiKit.button(text, Vector2(230, 70), 20, UiKit.TOXIC)
	b.pressed.connect(action)
	grid.add_child(b)
	return b


func _spawn_zombies() -> void:
	var spawner := EnemySpawner.find(get_tree())
	if spawner == null:
		return
	var wave := spawner.timeline.get_wave_at(GameState.elapsed)
	for i: int in 50:
		var p := spawner.offscreen_point()
		if p != Vector2.INF:
			spawner.manager.spawn(wave.enemies[i % wave.enemies.size()], p)


func _toggle_god() -> void:
	var player := Player.find(get_tree())
	if player == null:
		return
	player.health.god_mode = not player.health.god_mode
	_god_button.text = "INVENCÍVEL: %s" % ("SIM" if player.health.god_mode else "NÃO")


func _toggle_hard() -> void:
	_hard = not _hard
	var mult := 2.0 if _hard else 1.0
	Config.game.enemy_spawn_multiplier = mult
	Config.game.enemy_health_multiplier = mult
	_hard_button.text = "DIFICULDADE x%d" % roundi(mult)


func _teleport() -> void:
	var map := GameMap.find(get_tree())
	var player := Player.find(get_tree())
	if map == null or player == null:
		return
	var p := map.random_free_point_around(GameState.player_position, 30.0, _rng, 20)
	if p != Vector2.INF:
		player.teleport(p)
